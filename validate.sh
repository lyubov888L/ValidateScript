CURRENT_DIR=""
ERROR_ARRAY=() #ERROR_ARRAY+=('String') to append to end of array
SUCCESS_ARRAY=()
TOTAL_PROPS=0
TOTAL_PASS=0
TOTAL_FAIL=0

while read -r LINE; do
    #echo $LINE

    #If line is ADD, CHANGE, or DELETE
    if [[ "$LINE" == "(Add)" || "$LINE" == "(Change)" || "$LINE" == "(Delete)" ]] ; then
        #if [[ "$PROP_STATE" != "(Delete)" && "$LINE" == "(Delete)" ]] ; then
        #   echo " " #Skip a line to help output look better
        #fi

        PROP_STATE=$LINE


    #if it is a directory
    elif [[ "$LINE" ==  "/opt/"* ]] ; then
    #elif [[ -d "$LINE" ]] ; then #== "/opt/"*
        CURRENT_DIR=""

        #Replace [hostname] with the servers hostname in the directory line
        IFS='/' read -ra DIR <<< "$LINE"
        for SPLIT_DIR in "${DIR[@]}"; do
            # process "$SPLIT_DIR"
            if [[ "$SPLIT_DIR" == "[hostname]" ]] ; then
                CURRENT_DIR="$CURRENT_DIR/$(hostname -s)"
            elif [[ "$SPLIT_DIR" == "" ]] ; then
                TEST="" #DO NOTHING
            else
                CURRENT_DIR="$CURRENT_DIR/$SPLIT_DIR"
            fi
        done

    #If line is a property that needs to be validated
    elif [[ (("$LINE" == *"="*) || ($PROP_STATE == "(Delete)")) && "$LINE" != "" ]] ; then
        ((TOTAL_PROPS++)) #update TOTAL_PROPS to keep track of how many props we validate
        PROP=$( echo "$LINE" | cut -d '=' -f 1  )
        #echo $PROP
                                          

        GREP_RESPONSE=$( grep "$PROP=" "$CURRENT_DIR" )

        #If PROP_STATE is (Add) or (Change)
        if [[ "$PROP_STATE" == "(Add)" || "$PROP_STATE" == "(Change)"  ]] ; then
            if [[ "$GREP_RESPONSE" == "$LINE" ]] ; then
                ((TOTAL_PASS++))
                SUCCESS_ARRAY+=("Expected $LINE and found $GREP_RESPONSE in $CURRENT_DIR")
                #echo "$LINE is in $CURRENT_DIR"
            elif [[ "$GREP_RESPONSE" == "" ]] ; then
                ((TOTAL_FAIL++))
                ERROR_ARRAY+=("Expected $LINE and found NOTHING in $CURRENT_DIR")
                #echo "Could not find $LINE in $CURRENT_DIR"
            else
                ((TOTAL_FAIL++))
                ERROR_ARRAY+=("Expected $LINE and found $GREP_RESPONSE in $CURRENT_DIR")
                #echo "Found $GREP_RESPONSE in $CURRENT_DIR instead of $LINE"
            fi
        #If PROP_STATE is (Delete)
        else
            if [[ $GREP_RESPONSE == "" ]] ; then
                ((TOTAL_PASS++))
                SUCCESS_ARRAY+=("Expected not to find $LINE and found NOTHINIG in $CURRENT_DIR")
                #echo "$LINE is not in $CURRENT_DIR"
            else
                ((TOTAL_FAIL++))
                ERROR_ARRAY+=("Expected not to find $LINE and found $GREP_RESPONSE in $CURRENT_DIR")
                #echo "Found $GREP_RESPONSE in $CURRENT_DIR when $LINE is suppose to be deleted"
            fi
        fi
    fi
done <$1

echo "Out of $TOTAL_PROPS properties, $TOTAL_PASS passed, and $TOTAL_FAIL failed"
echo "ALL FAILS"
printf 'FAIL: %s\n' "${ERROR_ARRAY[@]}" #print out all the errors found

#Only show success array if the user wants it
if [[ $2 == "--success" ]] ; then
    echo ""
    echo ""
    echo "ALL PASSES"
    printf 'PASS: %s\n' "${SUCCESS_ARRAY[@]}" #print out all the successes found
fi