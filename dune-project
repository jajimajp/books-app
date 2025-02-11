(lang dune 2.7)

(name books-app)

(generate_opam_files true)

(license MIT)
(maintainers "Yajima Soichi <jajima.jp@gmail.com>")
(authors "Yajima Soichi <jajima.jp@gmail.com>")
(source (github jajimajp/books-app))
(documentation "https://github.com/jajimajp/books-app")

(package
 (name books-app)
 (synopsis "Book collection management app")
 (depends
  (ocaml (>= "4.08.0"))
  (dune (>= "2.0.0"))
  (dream (>= "1.0.0~alpha8"))
  (caqti-driver-postgresql (>= "2.1.2"))))

