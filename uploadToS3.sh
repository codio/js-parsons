#!/bin/bash
set -xe

s3Key=$1
s3Secret=$2
tag=$3
folder="guides\/parsons\/"
cdn="\/\/static-assets.codio.com\/${folder}\/${tag}"

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
  resource="/${bucket}/${folder}/${tag}/${fName}"
  dateValue=$(date -R)
  stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
  signature=$(echo -en "${stringToSign}" | openssl sha1 -hmac "${s3Secret}" -binary | base64)
  curl -X PUT -T "${file}" \
    -H "Host: ${bucket}.s3.amazonaws.com" \
    -H "Date: ${dateValue}" \
    -H "Content-Type: ${contentType}" \
    -H "Authorization: AWS ${s3Key}:${signature}" \
    https://${bucket}.s3.amazonaws.com/"${folder}"/"${tag}"/"${fName}" || exit 1
}

for file in "${files[@]}"
do
  contentType=$(getContentType "$file")
  uploadFile "$file" "$contentType"
done

uploadFile "parsons.js" "$(getContentType "parsons.js")"
uploadFile "parsons.css" "$(getContentType "parsons.css")"
