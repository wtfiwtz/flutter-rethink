package main

import (
	"context"
	"encoding/binary"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/websocket"
	r "gopkg.in/rethinkdb/rethinkdb-go.v6"
)

// const kOperationUnknown = 0
const kOperationListen  = 1
// const kOperationAdd     = 2

var gRethinkSession *r.Session = nil

func main() {
	gRethinkSession = rethinkDb()
	// helloWorld(gRethinkSession)
	var addr = flag.String("addr", "localhost:8081", "http service address")
	flag.Parse()
	http.HandleFunc("/ws", handler)
	// http.HandleFunc("/", home)
	log.Fatal(http.ListenAndServe(*addr, nil))
}

func rethinkDb() *r.Session {
	session, err := r.Connect(r.ConnectOpts{
		Address: "localhost:28015", // endpoint without http
	})
	if err != nil {
		log.Fatalln(err)
	}
	return session
}

func createResponse(session *r.Session, request []byte, messageType int, conn *websocket.Conn) []byte {
	var buffer []byte
	messageKind := binary.LittleEndian.Uint32(request[0:])
	if messageKind == kOperationListen {
		ctx := context.Background()
		requestId, response := listenRequest(session, request, &ctx, messageType, conn)
		buffer = writeAddObject(requestId, response)

	} else {
		fmt.Println("Unknown message kind: ", messageKind)
	}

	return buffer
}

//type Author struct {
//	ID string `gorethink:"ID"`
//	Name string `gorethink:"name"`
//}

func listenRequest(session *r.Session, request []byte, ctx *context.Context, messageType int, conn *websocket.Conn) (uint32,[]byte) {
	requestId := binary.LittleEndian.Uint32(request[4:])
	messagePathSize := binary.LittleEndian.Uint32(request[8:])
	path := request[12: (12 + messagePathSize)]

	fmt.Println("path: ", string(path))

	res, err := r.DB("test").Table(string(path)) /* .GetAll("0aacf2a8-27bd-4896-b75e-9e2a4d3cc235") */ .Run(session)
	if err != nil {
		log.Fatalln(err)
	}
	defer res.Close()

	var results []map[string]interface{} // use a map instead of struct - e.g. []Author
	err = res.All(&results)
	if err != nil {
		log.Println("No results?")
		log.Fatalln(err)
	}

	// fmt.Println(authors)

	json1, err := json.Marshal(results)
	if err != nil {
		log.Fatalln(err)
	}

	if ctx != nil {
		handleChanges(session, path, ctx, messageType, requestId, conn);
		// defer res.Close()
	}

	return requestId, json1
}

func handleChanges(session *r.Session, path []byte, ctx *context.Context, messageType int, requestId uint32, conn *websocket.Conn) {
	fmt.Println("Handle Changes")
	cursor, err := r.DB("test").Table(string(path)).Changes().Run(session)
	if err != nil {
		log.Fatalln(err)
	}

	// Shutdown the cursor to close when notified
	go func(ctx context.Context) {
		<-ctx.Done()
		fmt.Println("Received done")
		cursor.Close()
	}(*ctx)

	go func() {
		var changeFeed map[string]interface{}
		for cursor.Next(&changeFeed) {
			fmt.Println("Change", changeFeed)

			//if changeFeed["old_val"] != nil {
			//	//do something
			//}
			//

			if changeFeed["new_val"] != nil {
				json2, err := json.Marshal(changeFeed["new_val"])
				if err != nil {
					log.Fatalln(err)
				}

				buffer := writeAddObject(requestId, json2)
				if err := conn.WriteMessage(messageType, buffer); err != nil {
					log.Println(err)
					return
				}
			}
		}
	}()
}

func writeAddObject(requestId uint32, responseData []byte) []byte {
	response1 := make([]byte, 4)
	binary.LittleEndian.PutUint32(response1, requestId)
	response2 := make([]byte, 4)
	binary.LittleEndian.PutUint32(response2, uint32(len(responseData)))

	var full []byte
	full = append(full, response1...)
	full = append(full, response2...)
	full = append(full, responseData...)
	return full
}


func handler(w http.ResponseWriter, r *http.Request) {
	var upgrader = websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin: func(r *http.Request) bool {
			origin := r.Header.Get("Origin")
			fmt.Println(origin)
			return true // origin == "http://127.0.0.1:8081"
		},
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}
	defer conn.Close()

	for {
		messageType, request, err := conn.ReadMessage()
		if err != nil {
			log.Println(err)
			return
		}
		// fmt.Println("Got a message: ", messageType, " with size ", len(request));

		// formulate a response
		buffer := createResponse(gRethinkSession, request, messageType, conn)
		// fmt.Println("Response: ", buffer[0], "; ", buffer);

		if err := conn.WriteMessage(messageType, buffer); err != nil {
			log.Println(err)
			return
		}
	}
}
