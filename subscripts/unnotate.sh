if [ ${#1} == 0 ]
then
  notes_file=$HOME"/.universal_notes.txt"
else
  notes_file=$1
fi

if [ -f $notes_file ]
then
  vim $notes_file
else
  touch $notes_file
  vim $notes_file
fi
