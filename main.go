package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(res http.ResponseWriter, req *http.Request) {
		fmt.Fprint(res, "Hello Custom World!")
	})
	// setup routes for mux     // define your endpoints
	errs := make(chan error, 1) // a channel for errors
	go serveHTTP(mux, errs)     // start the http server in a thread
	go serveHTTPS(mux, errs)    // start the https server in a thread
	log.Fatal(<-errs)           // block until one of the servers writes an error

}

func serveHTTP(mux *http.ServeMux, errs chan<- error) {
	errs <- http.ListenAndServe(":8080", mux)
}

func serveHTTPS(mux *http.ServeMux, errs chan<- error) {
	errs <- http.ListenAndServeTLS(":8443", "/app/localhost.crt", "/app/localhost.key", mux)
}
