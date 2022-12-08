package main

import (
	"context"
	"log"
	"strconv"
	"time"

	"github.com/segmentio/kafka-go"
)

func main() {
	// to produce messages
	topic := "my-topic"
	partition := 0

	conn, err := kafka.DialLeader(context.Background(), "tcp", "localhost:9094", topic, partition)
	if err != nil {
		log.Fatal("failed to dial leader:", err)
	}

	var count = 0

	for {
		log.Println("Writing!")

		conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
		_, err = conn.WriteMessages(
			kafka.Message{Key: []byte(string(count)), Value: []byte(strconv.Itoa(count))},
		)
		if err != nil {
			log.Fatal("failed to write messages:", err)
		}

		count += 1
		log.Println(count)
		log.Println("Written!")
	}
}
