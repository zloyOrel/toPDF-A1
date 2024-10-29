#!/usr/bin/env bash
#Create by epifancev 01.07.2024

declare -r INPUT_DIR="/home/epic/tmp/in"
declare -r OUTPUT_DIR="/home/epic/tmp/out"
declare -r DOC_FILE_EXTENSION="doc|docx|odt|rtf|xls|xlsx"
declare -r PDF_FILE_EXTENSION="pdf"
declare -r LABEL_FOR_CONVERTED_FILE="PDFA1"

trString() {
   local string="$1"
   echo "$string" |      \
     sed -r 's/ +/_/g' | \
     sed -r 's/\-+//g' | \
     sed -e "y/йукенгзхъфывапролдэсмитьбЙУКЕНГЗХЪФЫВАПРОЛДЭСМИТЬБ/jukengzh6fyvaproldesmit6bJUKENGZH6FYVAPROLDESMIT6B/" \
      -e "s/ц/tz/g"  \
      -e "s/ш/sh/g"  \
      -e "s/щ/sch/g" \
      -e "s/ж/zh/g"  \
      -e "s/ч/ch/g"  \
      -e "s/ю/yu/g"  \
      -e "s/я/ya/g"  \
      -e "s/ё/yo/g"  \
      -e "s/Ё/YO/g"  \
      -e "s/Ц/TZ/g"  \
      -e "s/Ш/SH/g"  \
      -e "s/Щ/SCH/g" \
      -e "s/Ж/ZH/g"  \
      -e "s/Ч/CH/g"  \
      -e "s/Ю/YU/g"  \
      -e "s/?/_/g"   \
      -e "s/Я/YA/g"
}
getFileExtension() {
  local file="$1"
  echo "$file" | awk -F '.' '{print $NF}'
}
getFileNameWithoutExtension() {
  local fileName="$1" ; echo "$1" | sed 's/\.[^.]*$//'
}
getNewFileName() {
  local origFileName="$1"
  local newFileName; newFileName="$(getFileNameWithoutExtension "$origFileName")_""$LABEL_FOR_CONVERTED_FILE".$(getFileExtension "$origFileName")
  echo "$newFileName"
}
convertToPDFA1() {
  local dir="$1"
  inotifywait -e close_write --format '%w %f' -m "$dir" |\
  (
  while read -r
  do
      local input_dir; input_dir="$(echo "$REPLY" | cut -f 1 -d ' ' | tr -d ' ')"
      local fileName; fileName="$(echo "$REPLY" | awk -F '/' '{print $NF}' | sed 's/^[   ]*//;s/[    ]*$//')"
      local fileNameFullPath="$input_dir$fileName"
      local fileExtension; fileExtension=$(getFileExtension "$fileNameFullPath")
      if [[ "$fileExtension" =~ $DOC_FILE_EXTENSION ]]; then
        local fileNameNew; fileNameNew=$(trString "$(getNewFileName "$fileName")")
        local fileNameNewFullPath="$input_dir$fileNameNew"
        if [[ -f "$fileNameFullPath"  ]];then  #File isExists
          mv "$fileNameFullPath" "$fileNameNewFullPath"
          local status=$(lowriter --convert-to pdf --outdir "$OUTPUT_DIR" "$fileNameNewFullPath" >/dev/null 2>&1)  ; wait $!
          #the status of converting dock files can then be used somehow...
          rm -rf "$fileNameNewFullPath"
        fi
      fi

      if [[ "$fileExtension" == $PDF_FILE_EXTENSION ]]; then
        local fileNameNewFullPath="$input_dir$fileNameNew"
        local fileNameNew; fileNameNew=$(trString "$(getNewFileName "$fileName")")
        local fileNameNewFullPath="$OUTPUT_DIR/$fileNameNew"
        if [[ -f "$fileNameFullPath" ]]; then #File isExists
          local status=$(gs \
            -dPDFA \
            -dBATCH \
            -dNOPAUSE \
            -sColorConversionStrategy=UseDeviceIndependentColor \
            -sDEVICE=pdfwrite \
            -dPDFACompatibilityPolicy=2 \
            -sOutputFile="$fileNameNewFullPath" "$fileNameFullPath" >/dev/null 2>&1)
             wait $!
          #the status of converting dock files can then be used somehow...
          rm -rf "$fileNameFullPath"
        fi
      fi
  done
  )
}

main() {
  convertToPDFA1 "$INPUT_DIR"
}

main