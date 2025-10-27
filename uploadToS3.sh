#!/bin/bash
set -xe

joinByChar() {
  local IFS="$1"
  shift
  echo "$*"
}

tag=$1
folderArr=("guides" "parsons")
folder=$(joinByChar "/", "${folderArr[@]}")
folderEscaped=$(joinByChar "\/", "${folderArr[@]}")
cdn="\/\/static-assets.codio.com\/${folder}\/${tag}"

echo "$cdn"

readarray -d '' files < <(find ./lib -type f -print0)

getContentType () {
  filename=$1
  extension=${filename##*.}
  contentType="application/octet-stream"

  case $extension in
    "html" | "css")
      contentType="text/${extension}"
      ;;
    "js")
      contentType="application/javascript"
      ;;
    "png" | "jpg" | "gif")
      contentType="image/${extension}"
      ;;
    "svg")
      contentType="image/svg+xml"
      ;;
    "ttf" | "woff" | "woff2")
      contentType="font/${extension}"
      ;;
  esac
  echo "$contentType"
}

uploadFile () {
  file=$1
  fName="${file#./}"
  contentType=$2
  bucket="codio-assets"
  resource="s3://${bucket}/${folder}/${tag}/${fName}"
  
  aws s3 cp "${file}" "${resource}" --cache-control no-cache --content-type "${contentType}"
}

for file in "${files[@]}"
do
  contentType=$(getContentType "$file")
  uploadFile "$file" "$contentType"
done

uploadFile "parsons.js" "$(getContentType "parsons.js")"
uploadFile "parsons.css" "$(getContentType "parsons.css")"
