package com.google;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.api.services.bigquery.model.TableRow;
import com.google.api.services.bigquery.model.TableSchema;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import org.apache.beam.sdk.Pipeline;
import org.apache.beam.sdk.io.TextIO;
import org.apache.beam.sdk.io.gcp.bigquery.BigQueryIO;
import org.apache.beam.sdk.io.gcp.pubsub.PubsubIO;
import org.apache.beam.sdk.io.kafka.KafkaIO;
import org.apache.beam.sdk.options.Default;
import org.apache.beam.sdk.options.Description;
import org.apache.beam.sdk.options.PipelineOptions;
import org.apache.beam.sdk.options.PipelineOptionsFactory;
import org.apache.beam.sdk.transforms.DoFn;
import org.apache.beam.sdk.transforms.Flatten;
import org.apache.beam.sdk.transforms.ParDo;
import org.apache.beam.sdk.transforms.ParDo.MultiOutput;
import org.apache.beam.sdk.transforms.Values;
import org.apache.beam.sdk.values.PCollection;
import org.apache.beam.sdk.values.PCollectionList;
import org.apache.beam.sdk.values.PCollectionTuple;
import org.apache.beam.sdk.values.TupleTag;
import org.apache.beam.sdk.values.TupleTagList;
import org.apache.kafka.common.serialization.LongDeserializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Demo {
  private static final Logger LOG = LoggerFactory.getLogger(Demo.class);
  
  // Custom options
  public interface DemoOptions extends PipelineOptions {
    @Description("Bucket for reading batch requests.")
    @Default.String("NONE")
    String getBatchBucket();
    void setBatchBucket(String batchBucket);

    @Description("Project to execute on")
    @Default.String("NONE")
    String getSubProject();
    void setSubProject(String subProject);
  }
  
  // Create two outputs for our decoder
  static final TupleTag<TableRow> eventData = new TupleTag<TableRow>(){};
  static final TupleTag<TableRow> badData = new TupleTag<TableRow>(){};
  
  // Define our BigQuery schema in code
  static final Map<String, String> eventSchema;
  static final Map<String, String> badSchema;
  static {
    eventSchema = new HashMap<String, String>();
    eventSchema.put("Name", "STRING");
    eventSchema.put("UUID", "STRING");
    eventSchema.put("UserUUID", "STRING");
    eventSchema.put("Timestamp", "TIMESTAMP");

    badSchema = new HashMap<String, String>();
    badSchema.put("timestamp", "TIMESTAMP");
    badSchema.put("data", "STRING");
  }

  // DecodeMessage will decode a json message into a tablerow
  static class DecodeMessage extends DoFn<String, TableRow> {
    ObjectMapper objectMapper = new ObjectMapper();
    @ProcessElement
    public void processElement(ProcessContext c) {
      String data = c.element();
      TableRow output = new TableRow();
      try {
        output = objectMapper.readValue(data, TableRow.class);
      } catch (Exception e) {
        // This is bad data, let's make a tablerow of the string it
        // self and output it.
        output = new TableRow();
        output.set("timestamp",  System.currentTimeMillis() / 1000);
        output.set("data", data);
        c.output(badData, output);
        return;
      }
      c.output(output);
    }
  }

  public static TableSchema generateSchema(Map<String,String> fi) {
    List<TableFieldSchema> fields = new ArrayList<>();
    Iterator<Map.Entry<String,String>> it = fi.entrySet().iterator();
    while (it.hasNext()) {
      Map.Entry<String, String> pair = (Map.Entry<String, String>)it.next();
      fields.add(new TableFieldSchema().setName(pair.getKey()).setType(pair.getValue()));
    }
    return new TableSchema().setFields(fields);
  }

  // Entry point for our pipeline
  public static void main(String[] args) {
    PCollectionTuple decoded;
    DemoOptions options = PipelineOptionsFactory
      .fromArgs(args)
      .withValidation()
      .as(DemoOptions.class);

    Pipeline p = Pipeline.create(options);
    String subscription = "projects/"
    + options.getSubProject()
    + "/subscriptions/"
    + "pd-demo";
    
    // We're breaking out our decoder ParDo here into a variable.

    // Decode the JSON data from our subscription into two different outputs --
    // eventData, and badData. This illustrates a "mono" stream approach where
    // data from a stream can be split and worked differently depending on variables in the
    // data at run time.
    MultiOutput<String, TableRow> decode = ParDo.of(
      new DecodeMessage())
      .withOutputTags(eventData,
        TupleTagList.of(badData));


    // If our batch bucket is "NONE", we're streaming boys!
    if (options.getBatchBucket().equals("NONE")) {
      // Read from Pub/Sub
      PCollection<String> merged = p.apply("Read from Pub/Sub", PubsubIO.readStrings()
        .fromSubscription(subscription));

      // Let's decode (JSON -> Java TableRow) our inputs.
      decoded = merged.apply("Decode JSON into Rows", decode);
    } else {
      // Read from our batch bucket (or where ever really)
      decoded = p.apply("Read from GCS", TextIO.read()
        .from(options.getBatchBucket()))
        .apply("Decode JSON into Rows", decode);
    }
    
    // Write our good event data out.
    decoded.get(eventData)
    .apply("Write Events to BigQuery", BigQueryIO.writeTableRows()
      .to(options.getSubProject() + ":testing.eventData")
      .withSchema(generateSchema(eventSchema))
      .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
      .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_APPEND));

    // Write our bad data that we couldn't decode for later debugging.
    decoded.get(badData)
    .apply("Write Bad Data to BigQuery", BigQueryIO.writeTableRows()
      .to(options.getSubProject() + ":testing.badData")
      .withSchema(generateSchema(badSchema))
      .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
      .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_APPEND));

    // Run our pipeline!
    p.run().waitUntilFinish();
  }
}
