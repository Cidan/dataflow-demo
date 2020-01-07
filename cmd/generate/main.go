package main

import (
	"context"
	"encoding/json"
	"math/rand"
	"os"
	"os/signal"
	"time"

	"cloud.google.com/go/pubsub"
	"github.com/rs/zerolog/log"
	"golang.org/x/oauth2/google"
	"google.golang.org/api/compute/v1"
)

// FakeUser struct for pre-loading data
type FakeUser struct {
	Username  string
	UUID      string
	Created   time.Time
	LastLogin time.Time
	Updated   time.Time
	Gender    int
	Locale    string
	Likes     int64
}

// FakeEvent for fake data
type FakeEvent struct {
	Name      string
	UUID      string
	UserUUID  string
	Timestamp int64
	Metadata  map[string]interface{}
}

// This is silly, golang should allow const for slices
var eventNames = [...]string{
	"play_song",
	"pause_song",
	"stop_song",
	"play_song",
	"pause_song",
	"stop_song",
	"play_song",
	"like_song",
	"like_song",
	"like_song",
	"update_prefs",
	"login",
	"dance",
}

var recordTime = time.Now()
var faker int64

func init() {
	rand.Seed(time.Now().UnixNano())
}

func getProject() string {
	ctx := context.Background()
	credentials, err := google.FindDefaultCredentials(ctx, compute.ComputeScope)
	if err != nil {
		panic(err)
	}
	return credentials.ProjectID
}

func main() {
	log.Info().Msg("Connecting to Pub/Sub")
	client, err := pubsub.NewClient(context.Background(), getProject())
	if err != nil {
		log.Panic().Err(err).Msg("Error connecting to Pub/Sub")
	}

	// Create our topic
	topic := client.Topic("dataflow-stream-demo")
	exists, err := topic.Exists(context.Background())
	if err != nil {
		log.Panic().Err(err).Msg("Error checking for Pub/Sub topic")
	}

	if !exists {
		topic, err = client.CreateTopic(context.Background(), "dataflow-stream-demo")
		if err != nil {
			log.Panic().Err(err).Msg("Error creating topic")
		}
	}

	topic.PublishSettings.DelayThreshold = time.Second * 1

	for i := 0; i < 2; i++ {
		log.Info().Int("worker", i).Msg("Starting worker")
		go startWorker(topic)
	}

	// Wait until we get ctrl + c
	log.Info().Msg("Producing events, ctrl+c to exit...")
	<-SigIntChannel()
	log.Info().Msg("Exiting!")
}

// SigIntChannel returns a channel that gets a message
// on SIGINT
func SigIntChannel() chan os.Signal {
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	return c
}

// Start a fake event worker
func startWorker(topic *pubsub.Topic) {

	for {
		var data []byte
		var err error

		// Small chance to write bad data.
		if rand.Intn(100000) <= 1 {
			data = []byte("this is bad data I can't parse")
		} else {
			ev := &FakeEvent{
				Name:      eventNames[rand.Intn(len(eventNames)-1)],
				UUID:      randString(24),
				UserUUID:  randString(24),
				Timestamp: time.Now().Unix(),
			}
			data, err = json.Marshal(ev)
			if err != nil {
				continue
			}
		}
		// Write to pub/sub
		ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
		res := topic.Publish(ctx, &pubsub.Message{
			Data: data,
		})
		res.Get(ctx)
		cancel()
	}
}

var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func randString(n int) string {
	b := make([]rune, n)
	for i := range b {
		b[i] = letterRunes[rand.Intn(len(letterRunes))]
	}
	return string(b)
}
