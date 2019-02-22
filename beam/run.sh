cd first-dataflow
mvn compile exec:java \
				-Dexec.mainClass=com.google.Demo \
				-Dexec.args="--project=$1 \
--jobName=EventLog \
--stagingLocation=gs://$2/pd-demo \
--runner=DataflowRunner \
--numWorkers=20 \
--diskSizeGb=30 \
--experiments=shuffle_mode=service \
--subnetwork=\"regions/us-central1/subnetworks/default\" \
--streaming"
