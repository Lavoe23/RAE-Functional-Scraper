#! /usr/bin/env racket
#lang racket

;; ---------------------------------------------------------------------------------------------------
;; Project: RAE Functional Scraper
;; Description: Scrapes Real Academia Española (RAE) definitions using SXML parsing.
;; Stack: Racket (Functional Paradigm), SXML, HTML Parsing.
;; ---------------------------------------------------------------------------------------------------

(require html-parsing net/url sxml)

;; ===================================================================================================
;; 1. NETWORK & PARSING UTILITIES
;; ===================================================================================================

;; Fetch HTML content from a URL and convert it to SXML (Scheme XML)
(define page-get (lambda (url)
  (html->xexp
    (call/input-url (string->url url)
                    (curry get-pure-port #:redirections 2)
                    port->string))))

;; Build the RAE URL query
(define rae-url (lambda (palabra)
  (string-append "https://dle.rae.es/" palabra)))

;; Clean string inputs using regex (Tokenization)
;; Input: "hola, como estas" -> '("hola" "," "como" "estas")
(define text-to-list
  (lambda (str)
    (string-split
      (regexp-replace* #px"[.,;:¿?¡!-']"
      str
      (lambda (match)
        (string-append " " match " "))))))

;; Filter logic to remove stop-words and punctuation artifacts
(define useless-chars
  (lambda (str)
    (cond
      [(regexp-match-exact? #rx"[0-9]+" str) #f]
      [(string=? str ", ") #f]
      [(string=? str ": ") #f]
      [(string=? str " ") #f]
      [(string=? str ".") #f]
      [(string=? str ". ") #f]
      [(string=? str " (‖ ") #f]
      [(string=? str ").") #f]
      [else #t])))

;; Helper to join strings in a list
(define (juntar-str lst sep)
  (cond
    [(null? lst) ""]
    [(null? (cdr lst)) (car lst)]
    [else (string-append (car lst) sep (juntar-str (cdr lst) sep))]))

;; Recursively clean a list of strings
(define clean-list (lambda (lst)
  (cond
    [(null? lst) '()]
    [(pair? (car lst)) (cons (filter useless-chars (car lst)) (clean-list (cdr lst)))]
    (else (clean-list (cdr lst))))))

;; ===================================================================================================
;; 2. SCRAPING LOGIC (XPath Extraction)
;; ===================================================================================================

;; Generate SXML document from word
(define crear-doc-html (lambda (palabra)
  (page-get (rae-url palabra))))

;; Extract relevant paragraph nodes (p class="j")
(define html-info-palabra (lambda (sxml)
  ((sxpath "//p[contains(@class, 'j')]") sxml)))

;; Extract Word Title
(define get-word-title (lambda (sxml)
  (car ((sxpath "//header//text()") sxml))))

;; Extract Definition (Description)
;; Example: "m. y f. Hijo menor de una familia."
(define get-desc (lambda (sxml)
  (cons
    (car ((sxpath "//abbr/@title//text()") sxml)) ; Type (verb, noun, etc.)
    (list (juntar-str
      (list-tail (car (clean-list (list ((sxpath "/span//text()") sxml)))) 1)
      " ")))))

;; Extract Synonyms and Antonyms (if available)
(define get-sin-ant (lambda (sxml)
  (cond
    ((null? ((sxpath "//table//text()") sxml)) '()) ; Return empty if no table found
    (else
      (list (juntar-str
        (car (clean-list (list ((sxpath "//table//text()") sxml))))
        " "))))))

;; Combine Description + Synonyms
(define info-por-parte (lambda (sxml)
  (append (get-desc sxml) (get-sin-ant sxml))))

;; Map extraction function over all definitions found
(define info-total (lambda (sxml)
  (map info-por-parte (html-info-palabra sxml))))

;; ===================================================================================================
;; 3. CORE ANALYZER & MAIN LOOP
;; ===================================================================================================

;; Main Analysis Function: Orchestrates the scraping for a single word
(define analizar (lambda (str)
  (define html-doc (crear-doc-html str))
  (define sub-pagina ((sxpath "//div[contains(@class, 'n1')]//text()") (crear-doc-html str)))
  (cond
    [(and (null? (html-info-palabra html-doc)) (null? sub-pagina)) '()] ; Word not found
    [(null? (html-info-palabra html-doc)) (analizar (car sub-pagina))]  ; Handle redirects/suggestions
    (else
      (cons
          (string->symbol str)
          (cons
            (get-word-title html-doc)
            (info-total html-doc)))))))

;; Process user input sentence
(define process-user-input
  (lambda (user-text)
    (map analizar (text-to-list user-text))))

;; ENTRY POINT
(define main
  (lambda ()
    (displayln "---------------------------------------------------")
    (displayln " RAE FUNCTIONAL SCRAPER (USACH Edition) ")
    (displayln "---------------------------------------------------")
    (display "Ingrese texto a analizar > ")
    (define user-text (read-line))
    
    (displayln "\nProcesando (Conectando a RAE.es)...")
    (define results (process-user-input user-text))
    
    (displayln "Resultados:")
    (for-each (lambda (res) 
                (unless (null? res) (pretty-print res))) 
              results)))

;; Run the program
(main)
