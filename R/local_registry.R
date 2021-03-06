## Generic function that computes id first, then registers it against a specified local registry 
## (e.g. tsv_registry).  Local registries are database entry only, and do not compute the hash,
## they only store it.  

## Likewise, defines generic schema used by the local registry entry. 
## (Remote registries like hash-archive.org are also coerced into this schema)


registry_spec <- c("character","character", "POSIXct", "integer", "integer",
                   "character","character", "character","character", "character") 

## use base64 encoding for more space-efficient storage
registry_entry <- function(id = NA_character_, 
                           source = NA_character_, 
                           date = Sys.time(),
                           size = fs::file_size(source, FALSE),
                           status = 200L,
                           md5 = NULL, 
                           sha1 = NULL, 
                           sha256 = id, 
                           sha384 = NULL, 
                           sha512 = NULL){
  
  if(is.na(id)){
    status <- 404L
    size <- NA_integer_
  }
  as_chr <- function(x){
    if(is.null(x)) return(NA_character_)
    else as.character(x)
  }
  
  data.frame(identifier = as_chr(id), 
             source = as_chr(source), 
             date = as.POSIXct(date), 
             size = as.integer(size), 
             status = as.integer(status),
             md5 = as_hashuri(md5), 
             sha1 = as_hashuri(sha1), 
             sha256 = as_hashuri(sha256), 
             sha384 = as_hashuri(sha384), 
             sha512 = as_hashuri(sha512),
             stringsAsFactors = FALSE)
}

registry_cols <- names(registry_entry())

curl_err <- function(e) as.integer(gsub(".*(\\d{3}).*", "\\1", e$message))


# use '...' to swallow args for other methods
register_id <- function(source, 
                        algos = default_algos(),
                        registry =  default_tsv(),
                        register_fn = write_tsv,
                        ...
) {
  
  ## register will still refuse to fail, but record NAs when content_id throws and error
  id <- tryCatch(content_id(source, algos = algos, as.data.frame = TRUE),
                 error = function(e){
                   df <- registry_entry(NA_character_, source, status =  curl_err(e))
                   register_fn(df, registry)
                   df$id
                 },
                 finally = registry_entry(status = NA_integer_)
  )
  
  df <- registry_entry(id$sha256, source,  Sys.time(), 
                       md5 = id$md5, 
                       sha1 = id$sha1, 
                       sha256 = id$sha256, 
                       sha384 = id$sha384, 
                       sha512 = id$sha512)
  
  register_fn(df, registry)
  
  id$sha256
}


