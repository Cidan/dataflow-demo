package com.google;

import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.api.services.bigquery.model.TableSchema;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class Helpers {
  // Define our BigQuery schema in code
  static final Map<String, String> rawSchema;
  static final Map<String, String> badSchema;
  static final Map<String, String> rollupSchema;
  static {
    rawSchema = new HashMap<String, String>();
    rawSchema.put("event", "STRING");
    rawSchema.put("Name", "STRING");
    rawSchema.put("UUID", "STRING");
    rawSchema.put("UserUUID", "STRING");
    rawSchema.put("Timestamp", "TIMESTAMP");

    badSchema = new HashMap<String, String>();
    badSchema.put("timestamp", "TIMESTAMP");
    badSchema.put("data", "STRING");

    rollupSchema = new HashMap<String, String>();
    rollupSchema.put("event", "STRING");
    rollupSchema.put("total", "INTEGER");
    rollupSchema.put("timestamp", "TIMESTAMP");
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

}
