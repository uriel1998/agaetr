And also whether or not to shorten the thing needs to go here
And then once you have all these items, loops through the same way you do with
agaetr.

And if you want to put it in "buffer", you can do so by adding it to the 
posts.db section

This would be useful for just posting or for perhaps newsboat, etc

while getopts "k:t:l:c:i:a:b:d:" opt; do
    case $opt in
        k)  pubtime=$(echo "$OPTARG")
            ;;
        t)  title=$(echo "$OPTARG")
            ;;
        l)  link=$(echo "$OPTARG")
            ;;
        c)  cw=$(echo "$OPTARG")
            ;;
        i)  imgurl=$(echo "$OPTARG")
            ;;
        a)  imgalt=$(echo "$OPTARG")
            ;;
        b)  hashtags=$(echo "$OPTARG")
            ;;
        d)  description=$(echo "$OPTARG")
            ;;
        h)  show_help
            exit
            ;;        
    esac
done
shift $((OPTIND -1))


# if run standalone
# and only if run standalone
# run through urlshortener

#if urlshortener - then use urlshortener
# Requires a slightly modified version of 
# https://gist.github.com/uriel1998/3310028
# which only returns the shortened URL.
#shorturl=`bitly.py "$url"`

oysttytter_send
# NOW do function

# passing published day and month
#-k "pubtime" -t "title" -l "link" -c "CW" -i "imgurl" -a "imgalt" -b "hashtags" -d "description"
#time | title | link | CW,tag | imgalt | imgurl | hash,tags | description


# String whole thing together (twitter, so no CW - can we make one?)
