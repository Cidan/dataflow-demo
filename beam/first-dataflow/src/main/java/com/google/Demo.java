package com.google;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.api.services.bigquery.model.TableRow;
import com.google.bigtable.v2.Mutation;
import com.google.cloud.bigtable.config.BigtableOptions;
import com.google.common.collect.Iterables;
import com.google.protobuf.ByteString;

import java.util.Arrays;
import java.util.List;
import org.apache.beam.sdk.Pipeline;
import org.apache.beam.sdk.io.gcp.bigquery.BigQueryIO;
import org.apache.beam.sdk.io.gcp.pubsub.PubsubIO;
import org.apache.beam.sdk.io.gcp.bigquery.InsertRetryPolicy;
import org.apache.beam.sdk.io.gcp.bigquery.WriteResult;
import org.apache.beam.sdk.io.gcp.bigtable.BigtableIO;
import org.apache.beam.sdk.options.PipelineOptions;
import org.apache.beam.sdk.options.PipelineOptionsFactory;
import org.apache.beam.sdk.transforms.Combine;
import org.apache.beam.sdk.transforms.DoFn;
import org.apache.beam.sdk.transforms.Flatten;
import org.apache.beam.sdk.transforms.PTransform;
import org.apache.beam.sdk.transforms.ParDo;
import org.apache.beam.sdk.transforms.SerializableFunction;
import org.apache.beam.sdk.transforms.DoFn.ProcessElement;
import org.apache.beam.sdk.transforms.windowing.BoundedWindow;
import org.apache.beam.sdk.transforms.windowing.FixedWindows;
import org.apache.beam.sdk.transforms.windowing.Window;
import org.apache.beam.sdk.values.KV;
import org.apache.beam.sdk.values.PCollection;
import org.apache.beam.sdk.values.PCollectionList;
import org.apache.beam.sdk.values.PCollectionTuple;
import org.apache.beam.sdk.values.TupleTag;
import org.apache.beam.sdk.values.TupleTagList;
import org.joda.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// This is our main execution class for our Pipeline
public class Demo {
  private static final Logger LOG = LoggerFactory.getLogger(Demo.class);
  
  // We define three tags here for our decoded output (below). Each tag is a "split" in the stream,
  // which allows us to make runtime decisions about how to process data.
  static final TupleTag<TableRow> badData = new TupleTag<TableRow>(){};
  static final TupleTag<TableRow> rawData = new TupleTag<TableRow>(){};
  static final TupleTag<KV<String,TableRow>> windowData = new TupleTag<KV<String,TableRow>>(){};


  static class TableRowToMutation extends DoFn<TableRow, KV<ByteString, Iterable<Mutation>>> {
    @ProcessElement
    public void processElement(ProcessContext c) {

    }
  }
  // Here we define a static DoFn -- a function applied on every object in the stream.
  // This DoFn, DecodeMessage, will decode our incoming JSON data and split it into three
  // outputs as defined above.
  static class DecodeMessage extends DoFn<String, KV<String,TableRow>> {
    ObjectMapper objectMapper = new ObjectMapper();

    // This function will create a TableRow (BigQuery row) out of String data
    // for later debugging.
    public TableRow createBadRow(String data) {
      TableRow output = new TableRow();
      output.set("json", data);
      return output;
    }

    // Our main decoder function.
    @ProcessElement
    public void processElement(ProcessContext c) {
      // Get the JSON data as a string from our stream.
      String data = c.element();
      TableRow output;

      // Attempt to decode our JSON data into a TableRow.
      try {
        output = objectMapper.readValue(data, TableRow.class);
      } catch (Exception e) {
        // We were unable to decode the JSON, let's put this string
        // into a TableRow manually, without decoding it, so we can debug
        // it later, and output it as "bad data".
        c.output(badData, createBadRow(data));
        return;
      }

      // Incredibly simple validation of data -- we are simply making sure
      // the event key exists in our decoded JSON. If it doesn't, it's bad data.
      // If you need to validate your data stream, this would be the place to do it!
      if (!output.containsKey("Name")) {
        c.output(badData, createBadRow(data));        
        return;
      }

      // Output our good data twice to two different streams. rawData will eventually
      // be directly inserted into BigQuery without any special processing, where as
      // our other output (the "default" output), outputs a KV of (event, TableRow), where
      // event is the name of our event. This allows us to do some easy rollups of our event
      // data a bit further down.
      c.output(rawData, output);
      c.output(KV.of((String)output.get("Name"), output));
    }
  }

  // A simple combine function for our Rollup output that counts the number of events in
  // a window. This is used/instatiated a bit later in the file.
  public static class SumEvents implements SerializableFunction<Iterable<TableRow>, TableRow> {
    @Override
    public TableRow apply(Iterable<TableRow> input) {
      return new TableRow().set("total", Iterables.size(input));
    }
  }

  // A dead letter handler for failed inserts to BigQuery/errors in decoding. Inserts can fail
  // for a number of reasons, primarily when inserting data that doesn't match the schema of the
  // BigQuery table. This PTransform is applied to failed inserts and will serialize a TableRow
  // back into JSON so we can analyze it later.
  public static class DeadLetter extends PTransform<PCollection<TableRow>, WriteResult> {
    public String label;
    ObjectMapper objectMapper = new ObjectMapper();

    public DeadLetter(String name) {
      label = name;
    }

    @Override
    public WriteResult expand(PCollection<TableRow> rows) {
      // Convert the incoming dead letter item into a TableRow
      // that contains the string data for the item, and the timestamp
      // so we can analyze the failure at a later date.
      return rows.apply("Convert to Dead Letter", ParDo
      .of(new DoFn<TableRow, TableRow>(){
        @ProcessElement
        public void processElement(ProcessContext c) {
          TableRow r = new TableRow();
          try {
            r.set("data", objectMapper.writeValueAsString(c.element()));
            r.set("timestamp",  System.currentTimeMillis());
          } catch(Exception e) {
            LOG.error("Critical error saving dead letter object: "+ e.getMessage());
            return;
          }
          c.output(r);
        }
      }))
      // Save our dead letter items into BigQuery
      .apply("Dead Letter (" + label + ")", BigQueryIO.writeTableRows()
        .to("jinked-home:testing.badData")
        .withSchema(Helpers.generateSchema(Helpers.badSchema))
        .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
        .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_APPEND)
        .withFailedInsertRetryPolicy(InsertRetryPolicy.retryTransientErrors()));
    }
  }

  // Our main exeuction point for our pipeline. This is just like main
  // in any other Java program.
  public static void main(String[] args) {
    PipelineOptions options = PipelineOptionsFactory
      .fromArgs(args)
      .withValidation()
      .create();
    
    String subscription = "projects/"
    + "jinked-home"
    + "/subscriptions/"
    + "pd-demo";

    Pipeline p = Pipeline.create(options);

		// Read from Pubsub
		PCollectionTuple decoded = p.apply("Read from Pub/Sub", PubsubIO.readStrings()
        .fromSubscription(subscription))
    
    // Decode the messages into TableRow's (a type of Map), split by tag
    // based on how our decode function emitted the TableRow
    .apply("Decode JSON into Rows", ParDo
      .of(new DecodeMessage())
        .withOutputTags(windowData, TupleTagList
          .of(badData)
          .and(rawData)));
    
    // @decoded is now a single object that contains 3 streams, badData, rawData,
    // and windowData. This illustrates a "mono" stream approach where data from
    // a stream can be split and worked differently depending on variables in the
    // data at run time.

    // Write data that we couldn't decode (bad JSON, etc) to BigQuery
    decoded.get(badData)
    .apply("Send Dead Letter (Failed Decode)", new DeadLetter("Failed Decode"));

    // Write full, raw output, to a BigQuery table
    decoded.get(rawData)
    .apply("Raw to BigQuery", BigQueryIO.writeTableRows()
      .to("jinked-home:testing.rawData")
      .withSchema(Helpers.generateSchema(Helpers.rawSchema))
      .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
      .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_APPEND)
      .withFailedInsertRetryPolicy(InsertRetryPolicy.retryTransientErrors()))
      .getFailedInserts()
      .apply("Send Dead Letter (Raw)", new DeadLetter("Raw"));

    // Write full, raw output, to BigTable
    decoded.get(rawData)
    .apply("Create Mutation", ParDo
      .of(new TableRowToMutation()))
    .apply("Raw to BigTable", BigtableIO.write()
      .withProjectId("jinked-home")
      .withInstanceId("df-demo")
      .withTableId("df-demo"));
    // Process our previously decoded KV of (event, TableRow) outputs
    // and bucket them into 1 minute long buckets of data. Think of this
    // as a dam that opens the gates every minute.
    decoded.get(windowData)
    .apply("1 Minute Window", Window.<KV<String,TableRow>>
      into(FixedWindows
        .of(Duration.standardMinutes(1))))

    // Take our 1 minute worth of data and combine it by Key, and
    // call our previously defined SumEvents function. This will in turn
    // emit a series of KV (event, TableRows) for each unique event
    // type.
    .apply("Calculate Rollups", Combine.<String, TableRow>perKey(new SumEvents()))

    // Get the event name for this rollup, and apply it to the TableRow
    .apply("Apply Event Name", ParDo
      .of(new DoFn<KV<String, TableRow>, TableRow>(){
        @ProcessElement
        public void processElement(ProcessContext c, BoundedWindow window) {
          TableRow r = c.element().getValue();
          r.set("event", c.element().getKey());
          r.set("timestamp",window.maxTimestamp().getMillis() / 1000);
          c.output(r);
        }
      }))
    // Write our one minute rollups for each event to BigQuery
    .apply("Rollup to BigQuery", BigQueryIO.writeTableRows()
    .to("jinked-home:testing.rollupData")
    .withSchema(Helpers.generateSchema(Helpers.rollupSchema))
    .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
    .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_APPEND)
    .withFailedInsertRetryPolicy(InsertRetryPolicy.retryTransientErrors()))
    .getFailedInserts()
    .apply("Send Dead Letter (Rollups)", new DeadLetter("Rollups"));

    // Run our pipeline, and do not block/wait for execution!
    p.run();
  }
}
