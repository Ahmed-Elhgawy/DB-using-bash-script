#! /bin/bash

# define color in bash
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"

#==============================================================================================#
#                                 Create Table Function                                        #
#==============================================================================================#
createTable () {
    read -p " >    Enter name of table : " table_name # ==> take input from user

    # check if name is allowed
    allowed_pattern1='^[A-Za-z0-9_-]*$'
    while [[ ! $table_name =~ $allowed_pattern1 || $table_name =~ ^[0-9] ]] 
    do
        echo -e "${RED}   Invalid Name   ${RESET}"
        read -p " >    Enter name of table : " table_name # ==> retake input from user
    done
    shopt -s extglob
    export LC_COLLATE=C

    # check if table already exist
    if [ -f $table_name  ];then
        echo -e "${YELLOW}    Table Already Exist   ${RESET}"
    else
        touch $table_name # ==> file for data
        echo -e "${GREEN}    Table "$table_name" is Added SUCCESSFULLY   ${RESET}" 
        touch .$table_name # ==> file for metadata
        read -p " >    Enter ur field numbers : "  N
        allowed_pattern2='^[0-9]*$'
        while [[ ! $N =~ $allowed_pattern2 ]]
        do
            echo -e "${RED}   [ERROR] 'Invalid input'    ${RESET}"
            read -p "Enter ur field numbers : "  N
        done

        echo -e "${YELLOW}    The First Field Header is 'id'     ${RESET}" 
        header="id" 
        type="int" 
        echo "$header $type unique" > .$table_name
        for ((i=2;i<=N;i++))
        do
            read -p " >   Enter the field number $i header : " header 

            while [[ ! $header =~ $allowed_pattern1 || $header =~ ^[0-9] ]] 
            do
                echo -e "${RED}    Invalid INPUT    ${RESET}"
                read -p " >   Enter the field number $i header : " header
            done
            read -p " >   Enter the field type [str|int|any] (Default=any) : " type
            type="${type:-any}"
            until [[ $type = str || $type = int || $type = any ]]
            do
                echo -e "${RED}    [ERROR]    ${RESET}"
                echo "Please input correct type
                    str ==> String
                    int ==> Integer
                    any ==> any"
                read -p " >   Enter the field type [str|int|any] (Default=any) : " type
                type="${type:-any}" 
            done

            read -p " >   Is this field is unique ? [y|n] (Default=n)" PK
            PK="${PK:-n}"
            if [ $PK = "y" -o $PK = "Y" -o $PK = "yes" ];then
                echo "$header $type unique" >> .$table_name
            elif [ $PK = "n" -o $PK = "N" -o $PK = "no" ];then
                echo "$header $type" >> .$table_name
            fi
        done          
    fi
}

#==============================================================================================#
#                                 List Tables Function                                         #
#==============================================================================================#
listTables () {
    if [ -z "$(find . -type f)" ]; then
        echo -e "${YELLOW}    there is no Tables    ${RESET}"
    else
        echo -e "${GREEN}    The Founded Tables   ${RESET}"
        echo 
        ls -F | grep -v /
        echo
        # or find . -type f
    fi
}

#==============================================================================================#
#                                 Drop Table Function                                          #
#==============================================================================================#
dropTable () {
    read -p " >   Enter Table name want to delete : " table_name
    if [ -f $table_name ];then
        rm -r $table_name .$table_name
        echo -e "${GREEN}    REMOVED    ${RESET}"
    else
        echo -e "${RED}    There is no Table named '$table_name' in '$DB_name'    ${RESET}"
    fi
}

#==============================================================================================#
#                              Insert into Table Function                                      #
#==============================================================================================#
insert () {
    read -p " >   Enter Table name want to insert into : " table_name
    if [ -f $table_name ];then
        num=$(awk 'END { print NR }' ".$table_name") # ==> get the number of field in table
        echo -e "${YELLOW}    NOTE : you have $num field   ${RESET}"

        header=$(awk '{print $1}' ".$table_name") # ==> get the headers of fields
        type=$(awk '{print $2}' ".$table_name") # ==> get the types of fields
        unique=$(awk '{print $3}' ".$table_name") # ==> check if the field is the PK

        more=y
        while [[ $more = [Yy] ]]
        do
            echo $header > .header # ==> store headers in file
            echo $type > .type # ==> store types in file
            echo $unique >.unique # ==> store the check result of PK in file

            # loop to get input from user depend on number of fields
            for ((i=1;i<=$num;i++))
            do
                # var1 ==> variable to store headers
                # var2 ==> variable to store types
                # var3 ==> variable to store the check result of PK
                var1=$(awk '{print $1}' .header)
                cut -d' ' -f2- .header > tmpfile # ==> shift the element for next loop
                mv tmpfile .header # ==> save the result in real file
                var2=$(awk '{print $1}' .type)
                cut -d' ' -f2- .type > tmpfile # ==> shift the element for next loop
                mv tmpfile .type # ==> save the result in real file
                var3=$(awk '{print $1}' .unique)
                cut -d' ' -f2- .unique > tmpfile # ==> shift the element for next loop
                mv tmpfile .unique # ==> save the result in real file
                # take the inputs from user
                read -p " >  Enter '$var1' (Its type:'$var2') : " 
                # if this field PK we check that there is no dublicated value
                while [ ! -z $var3 ]
                do
                    cut -d " " -f1 $table_name > out.txt
                    result=$(grep "$REPLY" out.txt)
                    rm out.txt
                    if [[ $result =~ $REPLY ]];then
                        echo -e "${RED}   you can't duplicate element in this field    ${RESET}"
                        read -p " >  Enter '$var1' (Its type:'$var2') : "
                    else
                        break
                    fi    
                done
                
                # check type of input
                shopt -s extglob
                export LC_COLLATE=C
                case $var2 in
                    "str" )
                        allowed_pattern1='^[A-Za-z_-]*$'
                        while [[ ! $REPLY =~ $allowed_pattern1 ]]
                        do
                            echo -e "${RED}    Invalid type you should enter $var2   ${RESET}"
                            read -p " >  Enter '$var1' (Its type:'$var2') : " # ==> retake the input from user and check
                        done
                        echo $REPLY >> tmp.txt
                    ;;
                    "int" )
                        allowed_pattern2='^[0-9]*$'
                        while [[ ! $REPLY =~ $allowed_pattern2 ]]
                        do
                            echo -e "${RED}    Invalid type you should enter $var2   ${RESET}"
                            read -p " >  Enter '$var1' (Its type:'$var2') : " # ==> retake the input from user and check
                        done
                        echo $REPLY >> tmp.txt
                    ;;
                    "any" )
                        allowed_pattern3='^[A-Za-z0-9_-]*$'
                        while [[ ! $REPLY =~ $allowed_pattern3 ]]
                        do
                            echo -e "${RED}    Invalid type you should enter $var2   ${RESET}"
                            read -p " >  Enter '$var1' (Its type:'$var2') : " # ==> retake the input from user and check
                        done
                        echo $REPLY >> tmp.txt
                    ;;
                esac
            done

            # save the inputs in table
            result=$(awk '{print $1}' tmp.txt)
            echo $result >> $table_name
            # remove temporary files
            rm tmp.txt

            # check if user want to insert more
            read -p " > will you insert more? [y|n] (Default:Yes) " more # ==> if y > Go back 
            more="${more:-y}"   
        done

        # clear folder from empty lines & sort it
        grep -v '^$' $table_name > tmpfile && mv tmpfile $table_name 
        sort -o "$table_name" -k1,1n "$table_name"

        rm .header .type .unique -r # ==> clear from unused dir
    else
        echo -e "${RED}    There is no Table named '$table_name' in '$DB_name'    ${RESET}"
    fi
}

#==============================================================================================#
#                              Select from Table Function                                      #
#==============================================================================================#
selectfromtable () {
    read -p " > Enter Table name you want : " table_name
    if [ -f $table_name ];then
        echo "============================================================================================"
        echo "                                      '$table_name' Menu                                    "
        echo "============================================================================================"
        PS3="$DB_name Menu/$table_name : " # ==> change it based on menu
        select show in "Enter [A] to Show All" "Enter [C] to Show Specific Columns" "Enter [E] to Show Specific Elements" "Enter [Q] to Exit"
        do
            case $REPLY in 
                "A" | "a" ) # ==> Show All
                    if [ -s "$table_name" ]; then
                        echo "============================================================================================"
                        cat $table_name
                        echo "============================================================================================"
                    else
                        echo -e "${YELLOW}    The file $table_name is empty     ${RESET}"
                    fi 
                ;;
                "C" | "c" ) # ==> Show Specific Columns
                    num=$(awk 'END { print NR }' ".$table_name")
                    # show field name to user
                    header=$(awk '{print $1}' ".$table_name") 
                    # echo -e "${GREEN}"$header"${RESET}"
                    echo -e "${YELLOW}   NOTE : you have '$num' columns they are ${RESET}" "${GREEN}"$header"${RESET}"
                    read -p " > Choose the number of column you want to show : " n
                    allowed_pattern='^[0-9]*$'
                    while [[ $n > $num || ! $n =~ $allowed_pattern ]]
                    do
                        echo -e "${RED}   Please input number from 1 to $num   ${RESET}"
                        read -p " > Choose the number of column you want to show : " n
                    done
                    echo "============================================================================================"
                    cut -d " " -f$n $table_name
                    echo "============================================================================================"
                ;;
                "E" | "e" ) # ==> Show Specific Elements 
                    read -p " >  enter the element you search about : " element
                    echo "============================================================================================"
                    grep -iw "$element" $table_name
                    echo "============================================================================================"
                ;;
                "Q" | "q" ) # ==> Exit
                    echo "============================================================================================"
                    echo "                                    '$DB_name' Menu                                         "
                    echo "============================================================================================"
                    PS3="$DB_name Menu : " # ==> change it based on menu
                    break

                ;;
                * )
                    echo -e "${RED}    [ERROR]    ${RESET}"
                    echo ">     '  Please Enter a correct choose from menu 
                                    A ==> Show All
                                    C ==> Show Specific Columns
                                    E ==> Show Specific Elements
                                    Q ==> Exit ' "
                ;;
            esac
        done
    else
        echo -e "${RED}    There is no Table named '$table_name' in '$DB_name'    ${RESET}"
    fi
}

#==============================================================================================#
#                              Delete from Table Function                                      #
#==============================================================================================#
deletefromtable () {
    read -p " > Enter Table name you want to remove from it : " table_name
    if [ -f $table_name ];then
        read -p " >  you want to delete Row or Column [R|C] " var
        until [[ $var = [Rr] || $var = [Cc]  ]]
        do
            echo -e "${RED}   [Wrong Input]    ${RESET}"
            echo -e "please enter 
                R ==> Row
                c ==> Column" 
            read -p " >  you want to delete Row or Column [R|C] " var
        done
        if [[ $var = [Rr] ]];then
            read -p " > Enter the id of line want to delete : " id
            exist=$(awk -v term="$id" '$1 == term' "$table_name")
            echo $exist > tmpfile.txt
            element=$(awk '{print $1}' "tmpfile.txt")
            if [ -z $element ];then
                echo -e "${RED}   the table  doesn't contain this $id  ${RESET}"
            else
                awk -v term="$id" '$1 != term' "$table_name" > tmpfile
                mv tmpfile "$table_name"
                echo -e "${GREEN}   ROW is Deleted    ${RESET}"
            fi
            rm tmpfile.txt
        elif [[ $var = [Cc] ]];then
            num=$(awk 'END { print NR }' ".$table_name")
            header=$(awk '{print $1}' ".$table_name") 
            echo -e "${YELLOW}   NOTE : you have '$num' columns they are ${RESET}" "${GREEN}"$header"${RESET}"
            read -p " >  Enter column number to delete : " column_number_to_delete
            while [ $column_number_to_delete -gt $num ]
            do
                echo -e "${RED}    the table contain only $num columns    ${RESET}"
                read -p " >  Enter column number to delete : " column_number_to_delete
            done
                awk -v col="$column_number_to_delete" 'BEGIN { OFS=" " } { $col=""; $0=$0; print $0 }' "$table_name" > tmpfile
                mv tmpfile "$table_name"
                echo -e "${GREEN}   column$column_number_to_delete is deleted   ${RESET}"
        fi
    else
        echo -e "${RED}    There is no Table named '$table_name' in '$DB_name'    ${RESET}"
    fi
}

#==============================================================================================#
#                                 Update Table Function                                        #
#==============================================================================================#
updatetable () {
        read -p " >   Enter Table name want to update : " table_name
    if [ -f $table_name ];then
        echo "============================================================================================"
        echo "                                      '$table_name' Menu                                    "
        echo "============================================================================================"
        PS3="$DB_name Menu/$table_name : " # ==> change it based on menu
        select show in  "Enter [C] to Update in Field" "Enter [R] to Update in Row" "Enter [A] to Add New Field" "Enter [Q] to Exit"
        do
            case $REPLY in
                "C" | "c" ) # ==> Update in Field
                    num=$(awk 'END { print NR }' ".$table_name")
                    header=$(awk '{print $1}' ".$table_name") 
                    echo -e "${YELLOW}   NOTE : you have '$num' columns they are ${RESET}" "${GREEN}"$header"${RESET}"
                    read -p " >  Enter field number : " field_number
                    allowed_pattern1='^[0-9]*$'
                    # check the field_number
                    while [[ $field_number > $num || $field_number =~ 1 || ! $field_number =~ $allowed_pattern1 ]]
                    do
                        if [[ $field_number > $num ]];then
                            echo -e "${RED}   Please input number from 1 to $num   ${RESET}"
                            read -p " >  Enter field number : " field_number
                        elif [[ $field_number =~ 1 ]];then
                            echo -e "${RED}   You can't modify on this Filed   ${RESET}"
                            read -p " >  Enter field number : " field_number
                        elif [ [! $field_number =~ $allowed_pattern ]];then
                            echo -e "${RED}   Please input number from 1 to $num   ${RESET}"
                            read -p " >  Enter field number : " field_number
                        fi
                    done

                    read -p " >  Enter element you want to replace : " elem
                    
                    # check the element input
                    until [ ! -z $elem ] | grep -qw "$elem" "$table_name"
                    do
                        echo -e "${RED}   Element '$elem' not found in '$table_name'    ${RESET}"
                        read -p " >  Enter element you want to replace : " elem
                    done

                    read -p " >  Enter new element : " new_elem
                    
                    # check the new element input
                    allowed_pattern2='^[A-Za-z0-9_-]*$'
                    while [[ ! $new_elem =~ $allowed_pattern2 ]] || [ -z $new_elem ]
                    do
                        echo "${RED}    Invalid Input   ${RESET}"
                        read -p " >  Enter new element : " new_elem
                    done
                    
                    # Replace the element
                    awk -v search="$elem" -v replacement="$new_elem" -v field="$field_number" '{
                        for (i=1; i<=NF; i++) {
                            if (i == field && $i == search) {
                                $i = replacement
                            }
                        }
                        print
                    }' "$table_name" > tmp
                    mv tmp "$table_name"

                    echo -e "${GREEN} Elemnet Replaced SUCCESSFULLY ${RESET}"
                ;;
                "R" | "r" ) # ==> Update in Row
                    read -p " >  Enter row id : " id
                    cut -d ' ' -f 1 "$table_name" > tmp

                    # check the row_number
                    allowed_pattern1='^[0-9]*$'
                    until [  $id = $allowed_pattern1 ] | grep -qiw "$id" tmp
                    do
                        if [ $id = $allowed_pattern1 ];then
                            echo -e "${RED}    Invalid Input   ${RESET}"
                            read -p " >  Enter row id : " id
                        else
                            echo -e "${RED}    '$table_name' doesn't have this id    ${RESET}"
                        fi
                    done
                    rm tmp

                    row_number=$(grep -niw $id "$table_name" | cut -d ':' -f 1)

                    read -p " >  Enter element you want to replace : " elem

                    # check the element input
                    until [ ! -z $elem ] | grep -qw "$elem" "$table_name"
                    do
                        echo -e "${RED}   Element '$elem' not found    ${RESET}"
                        read -p " >  Enter element you want to replace : " elem
                    done

                    read -p " >  Enter new element : " new_elem

                    # check the new element input
                    allowed_pattern2='^[A-Za-z0-9_-]*$'
                    while [[ ! $new_elem =~ $allowed_pattern2 ]] || [ -z $new_elem ]
                    do
                        echo -e "${RED}   Invalid Input     ${RESET}"
                        read -p " >  Enter new element : " new_elem
                    done

                    # Replace the element
                    sed "${row_number} s/$elem/$new_elem/" "$table_name" > tmp
                    mv tmp "$table_name"

                    echo -e "${GREEN} Elemnet Replaced SUCCESSFULLY ${RESET}"
                ;;
                "A" | "a" ) # ==> Add Field
                    read -p " >  Enter the New Field header : " header 

                    allowed_pattern1='^[A-Za-z0-9_-]*$'
                    while [[ ! $header =~ $allowed_pattern1 || $header =~ ^[0-9] ]] 
                    do
                        echo -e "${RED}    Invalid Input      ${RESET}"
                        read -p " >  Enter the field header : " header
                    done

                    read -p " >   Enter the field type [str|int|any] (Default=any) : " type
                    type="${type:-any}" 
                    until [[ $type = str || $type = int || $type = any ]]
                    do
                        echo -e "${RED}    [ERROR]    ${RESET}"
                        echo "Please input correct type
                            str ==> String
                            int ==> Integer
                            any ==> any"
                        read -p " >   Enter the field type [str|int|any] (Default=any) : " type
                        type="${type:-any}"  
                    done

                    read -p " >   Is this field is unique ? [y|n] (Default=n)" PK
                    PK="${PK:-n}"
                    if [ $PK = "y" -o $PK = "Y" -o $PK = "yes" ];then
                        echo "$header $type unique" >> .$table_name
                    elif [ $PK = "n" -o $PK = "N" -o $PK = "no" ];then
                        echo "$header $type" >> .$table_name
                    fi

                    echo -e "${GREEN} Field Added SUCCESSFULLY ${RESET}"
                ;;
                "Q" | "q" ) # ==> Exit
                    echo "============================================================================================"
                    echo "                                    '$DB_name' Menu                                         "
                    echo "============================================================================================"
                    PS3="$DB_name Menu : " # ==> change it based on menu
                    break

                ;;
                * )
                    echo -e "${RED}    [ERROR]    ${RESET}"
                    echo ">     '  Please Enter a correct choose from menu 
                                    C ==> Update in Column
                                    R ==> Update in ROW
                                    A ==> Add Field
                                    Q ==> Exit ' "
                ;;
            esac
        done
    else
        echo -e "${RED}    There is no Table named '$table_name' in '$DB_name'    ${RESET}"
    fi
}

#==============================================================================================#
#                                 DB Menu Function                                             #
#==============================================================================================#
DBmenu () {
    echo "============================================================================================"
    echo "                                         '$DB_name' Menu                                    "
    echo "============================================================================================"

    PS3="$DB_name Menu : " # ==> change it based on menu
    select Table in "Enter [C] to Create Table" "Enter [L] to List Tables" "Enter [D] to Drop Table" "Enter [I] to Insert into Table" "Enter [S] to Select from Table" "Enter [R] to Delete from Table" "Enter [U] to Update Table" "Enter [Q] to Exit"
    do
        case $REPLY in
            "C" | "c" ) # ==> Create Table 
                createTable
            ;;
            "L" | "l" ) # ==> List Tables 
                listTables
            ;;
            "D" | "d" ) # ==> Drop Table 
                dropTable
            ;;
            "I" | "i" ) # ==> Insert into Table 
                insert
            ;;
            "S" | "s" ) # ==> Select from Table
                selectfromtable 
            ;;
            "R" | "r" ) # ==> Delete from Table 
                deletefromtable
            ;;
            "U" | "u" ) # ==> Update Table
                updatetable 
            ;;
            "Q" | "q" ) # ==> Exit
                cd ..
                echo "============================================================================================"
                echo "                                        Main Menu                                           "
                echo "============================================================================================"
                
                PS3="Main Menu : " # ==> change it based on menu
                break

            ;;
            * )
                echo -e "${RED}    [ERROR]    ${RESET}"
                echo ">     '  Please Enter a correct choose from menu 
                                C ==> Create Table
                                L ==> List Tables
                                D ==> Drop Table
                                I ==> Insert into Table
                                S ==> Select from Table
                                D ==> Delete from Table
                                U ==> Update Table
                                Q ==> Exit ' "
            ;;
        esac
    done
}

#==============================================================================================#
#                                  Create DB Function                                          #
#==============================================================================================#
createDB () {
    read -p " >   Enter DB Name : " DB_name # ==> take input

    # check if name is allowed
    allowed_pattern='^[A-Za-z0-9_-]*$'
    while [[ ! $DB_name =~ $allowed_pattern || $DB_name =~ ^[0-9] ]] 
    do
        echo -e "${RED}      [invalid name]      ${RESET}"
        read -p "$ >   Enter DB Name : " DB_name
    done
    shopt -s extglob
    export LC_COLLATE=C

    # check if DB already exist
    if [ -d $DB_name  ];then
        echo -e "${YELLOW}    already exist    ${RESET}"
    else
        mkdir $DB_name # ==> create DB
        echo -e "${GREEN}    database "$DB_name" is added    ${RESET}"
    fi
}

#==============================================================================================#
#                                  List DBs Function                                           #
#==============================================================================================#
listDBs () {
    if [ -z "$(ls -A)" ]; then
        echo -e "${YELLOW}    there is no DBs    ${RESET}"
    else
        echo -e "${GREEN}    The Founded DBs   ${RESET}"
        echo 
        ls -F | grep "/"
        echo
        # or find . -type d
    fi
}

#==============================================================================================#
#                                  Drop DB Function                                            #
#==============================================================================================#
dropDB () {
    read -p " >    Enter DB you want to delete : " DB_name
    if [ -d $DB_name ];then
        rm -r $DB_name
        echo -e "${GREEN}    REMOVED    ${RESET}"
    else
        echo -e "${RED}    There is no DB named '$DB_name'    ${RESET}"
    fi
}

#==============================================================================================#
#                                 Connect to DB Function                                       #
#==============================================================================================#
connecttoDB () {
    read -p " >    Enter DB name you want to connect to : " DB_name
    while [ -z $DB_name ]
    do
        read -p " >    Enter DB name you want to connect to : " DB_name
    done
    if [ -d $DB_name ];then
        cd $DB_name
        echo -e "${GREEN}   CONNECTED   ${RESET}"
        echo -e "${GREEN}   Now you are in '$DB_name'   ${RESET}"
        DBmenu
    else
        echo -e "${RED}    There is no DB named '$DB_name'    ${RESET}" 
        read -p "do you want to make it ? '[y|n]' " 
        if [ $REPLY = y ];then
            mkdir $DB_name
            cd $DB_name
            echo -e "${GREEN}   CONNECTED   ${RESET}"
            echo -e "${GREEN}   Now you are in '$DB_name'   ${RESET}"
            DBmenu
        else
            echo -e "${YELLOW}    Please try to input DB name correctly ${RESET}"
        fi
    fi
}

#==============================================================================================#
#                                  Begin MyDB                                                  #
#==============================================================================================#

# Check the existance of MyDB and create it in case it doesn't exist 
# Check and create in current location
location=$(pwd)
if [ -d "MyDB" ];then
    cd $location/MyDB
    #welcoming
    read -p " >   login name : " user
    echo "==========================================================================================================="
    echo "
                                             __  __           _____    ____  
                                            |  \/  |         |  __ \  |  _ \ 
                                            | \  / |  _   _  | |  | | | |_) |
                                            | |\/| | | | | | | |  | | |  _ < 
                                            | |  | | | |_| | | |__| | | |_) |
                                            |_|  |_|  \__, | |_____/  |____/ 
                                                       __/ |                 
                                                      |____|                   
                                                                                    Welcome '$user'           "
    echo "==========================================================================================================="
elif [ -f "MyDB" ];then
    echo -e "${RED}    WARNING ==>     ${RESET}"
    echo -e "${RED}    there a file named MyDB we changed it to MyDB.file    ${RESET}"
    mv MyDB MyDB.file
    mkdir $location/MyDB -p
    cd $location/MyDB
    #welcoming
    read -p " >    login name : " user
    echo "==========================================================================================================="
    echo "
                                             __  __           _____    ____  
                                            |  \/  |         |  __ \  |  _ \ 
                                            | \  / |  _   _  | |  | | | |_) |
                                            | |\/| | | | | | | |  | | |  _ < 
                                            | |  | | | |_| | | |__| | | |_) |
                                            |_|  |_|  \__, | |_____/  |____/ 
                                                       __/ |                 
                                                      |____|                   
                                                                                    Welcome '$user'           "
    echo "==========================================================================================================="
else
    mkdir $location/MyDB -p
    cd $location/MyDB
    #welcoming
    read -p " >    login name : " user
    echo "==========================================================================================================="
    echo "
                                             __  __           _____    ____  
                                            |  \/  |         |  __ \  |  _ \ 
                                            | \  / |  _   _  | |  | | | |_) |
                                            | |\/| | | | | | | |  | | |  _ < 
                                            | |  | | | |_| | | |__| | | |_) |
                                            |_|  |_|  \__, | |_____/  |____/ 
                                                       __/ |                 
                                                      |____|                   
                                                                                    Welcome '$user'           "
    echo "==========================================================================================================="
fi


echo "============================================================================================"
echo "                                      Main Menu                                             "
echo "============================================================================================"

PS3="Main Menu : " # ==> change it based on menu 
select DB in "Enter [C] to Create DB" "Enter [L] to List DBs" "Enter [D] to Drop DB" "Enter [S] to Connect to DB" "Enter [Q] to Exit"
do
    case $REPLY in
        "C" | "c" ) # ==> Create DB 
            createDB
        ;;
        "L" | "l" ) # ==> List DBs
            listDBs 
        ;;
        "D" | "d" ) # ==> Drop DB 
            dropDB
        ;;
        "S" | "s" ) # ==> Connect to DB 
            connecttoDB
        ;;
        "Q" | "q" ) # ==> Exit
            cd $location
            echo "============================================================================================"
            echo "                                           BYE                                              "
            echo "============================================================================================"
            break

        ;;
        * )
            echo -e "${RED}    [ERROR]    ${RESET}"
            echo ">     '  Please Enter a correct choose from menu 
                            C ==> Create DB
                            L ==> List DBs
                            D ==> Drop DB
                            S ==> Connect to DB
                            Q ==> Exit ' "
        ;;
    esac
done