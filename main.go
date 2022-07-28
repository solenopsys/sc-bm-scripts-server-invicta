package main

import (
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"os"
	"time"
)

func setCorsHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

func cors(fs http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// do your cors stuff
		// return if you do not want the FileServer handle a specific request
		setCorsHeaders(w)
		fs.ServeHTTP(w, r)
	}
}

func main() {
	baseDir := os.Getenv("baseDir")

	r := mux.NewRouter()

	pr := "/"
	r.PathPrefix(pr).Handler(http.StripPrefix(pr, cors(http.FileServer(http.Dir(baseDir)))))
	http.Handle("/", r)

	host := os.Getenv("server.Host")
	port := os.Getenv("server.Port")

	log.Println("START SERVER host,port ", host, " ", port)
	log.Println("DIR ", baseDir)
	addr := host + ":" + port

	srv := &http.Server{
		Handler: r,
		Addr:    addr,
		// Good practice: enforce timeouts for servers you create!
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Fatal(srv.ListenAndServe())
}
