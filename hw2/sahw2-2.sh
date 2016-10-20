#!/bin/sh

if ! [ -d ~/.mybrowser ]; then
	mkdir ~/.mybrowser
fi

if ! [ -f ~/.mybrowser/userterm ]; then
	echo "userterm">~/.mybrowser/userterm
fi

if ! [ -d ~/Downloads ]; then
	mkdir ~/Downloads
fi

if ! [ -f ~/.mybrowser/helppage ]; then
	echo "URL  -> go to the url
/S  -> show the source code
/L  -> select a link to go
/D  -> select a link to download
/B  -> bookmark
/H  -> helppage
/pp -> previous page
/np -> next page
!\${cmd} -> execute the shell command">~/.mybrowser/helppage
fi







alias dialog='dialog --title "browser"'
alias curlcheck='curl -o /dev/null -s -w "%{http_code}"'

home_url="http://google.com"
cur_url="http://nasa.cs.nctu.edu.tw"
cmd=""
bmselect=""
tempurl="google.com"
history_index="0"

checkterms(){
	dialog --title "terms" --yesno "$(cat ~/.mybrowser/userterm)" 200 100

	if [ "$?" -eq 1 ]; then
		dialog --title "Apology" --msgbox "Sorry, you can't use this browser if you don't agree the user terms" 200 100
		exit
	fi
}
gotopage(){
	file=$(mktemp)
	
	#----------------browse history------------------
	if [ "$1" != "norecord" ]; then
		if ! [ $history_index -eq 0  ]; then
			sed -i "" $((history_index+1))",\$d" ~/.mybrowser/.browse_history
		fi
		echo "$cur_url">> ~/.mybrowser/.browse_history
		history_index=$((history_index+1))
	fi

	#----------------get html content and show in testbox-----------------
	w3m -dump $cur_url>$file
	dialog --textbox $file 200 100

	rm $file
}
inputpage(){
	#----------------redirect input content to stdout---------------
	cmd=$(dialog --inputbox "$cur_url" 200 100 3>&1 1>&2 2>&3 3>&-)
	if [ "$?" -eq 0 ]; then
		checkcmd
	else
		exit
	fi 
}
findlink(){
	#----------------check path (../,/xx,xx/,./,........)----------------------	
	link=$(curl -skL $cur_url|grep -E "<a href"|cut -d'"' -f2 | \
		awk -v url=$cur_url 'BEGIN{
			num=1
		}
		{
	

				
			if ( url ~ "/ *$" ){
				"echo "url" |sed \"s/\\/ *$//g\""|getline url

			};
			
			"echo "url"|sed \"s/^.*:\\/\\///g\"|cut -d'\\/' -f1"|getline rootA;
			"echo "url"|sed \"s/:\\/\\/.*$//g\""| getline rootB;
			url_root=(rootB)"://"(rootA);

			if ( $0 ~ "://" ){
				print num" \""$0"\""
				num++
				next
			};
			if ( $0 ~ "^ */" ){
				print num" \""(url_root)$0"\""
				num++
				next
			};
			if ( $0 !~ "^ *\\.\\./" && $0 !~"^ *\\./" ){
				print num" \""url"/"$0"\""	
				num++
			}
			if ( $0 ~ "^ *\\.\\./" || $0 ~ "^ *\\./" ){
				"echo "$0"|sed \"s/\\.\\//\\//g\"|sed \"s/\\/\\//\\//g\"|sed \"s/\\.\\//\\.\\.\\//g\"|sed \"s/^ *\\///g\"|sed \"s/\\/ *$//g\""|getline iteration
				"echo "iteration"|grep -o \"\\/\"|wc -l "|getline count
				count++
				
				for(i=1;i<=count;i++){
					"echo "iteration"|cut -d'\\/' -f"i|getline path
					if( path == ".."){
						if(url_root != url ){
							"echo "url"|sed \"s/\\/[^\\/]*$//g\""|getline url
						}
					}
					else{
						url=(url)"/"(path)
					}
				}
				print num" \""url"\""
				num++
			}
			
			
		}' )
	#--------------------goto link------------------
	if ["$link" -eq ""];then
		dialog --msgbox "No Links in this page" 200 100
		gotopage "norecord"
		return
	fi

	#--------------------check action: download or go to link-----------------------
	if [ "$1" = "-link" ]; then
	
		linkselect=$(echo $link|xargs dialog --menu "Link:" 200 100 20 3>&1 1>&2 2>&3 3>&-)
		
		if [ $? -eq 1 -o $? -eq 255 ]; then
			gotopage "norecord"
			return
		else
			cur_url=$(echo $link|cut -d'"' -f$((linkselect*2)))
			gotopage
			
		fi
	else
		if [ "$1" = "-download" ]; then
			linkselect=$(echo $link|xargs dialog --menu "Download:" 200 100 20 3>&1 1>&2 2>&3 3>&-)
			if [ $? -eq 1 -o $? -eq 255 ]; then
				gotopage "norecord"
				return
			else
				down_url=$(echo $link|cut -d'"' -f$((linkselect*2)))
				wget -qP ~/Downloads/ "$down_url"	
				gotopage "norecord"
			fi
		fi
	fi
}
source(){
	#--------------download source and show it in textbox----------------
	file=$(mktemp)
	curl -skL $cur_url>$file
	
	dialog --textbox $file 200 100
	rm $file
}
bookmark(){
	if ! [ -f ~/.mybrowser/bookmark ]; then
		"">~/.mybrowser/bookmark
	fi
	bookmark="1 \"Add a_bookmark\" \
			2 \"Delete a_bookmark\" "
	bookmark=$bookmark$(cat ~/.mybrowser/bookmark|awk 'BEGIN{num=3}{print num" \""$0"\""}{num=num+1}')
	bmselect=$(echo $bookmark|xargs dialog --menu "Bookmarks:" 200 100 10 3>&1 1>&2 2>&3 3>&-)
	if [ $? -eq 1 -o $? -eq 255 ]; then
		gotopage "norecord"
		return
	fi
	case $bmselect in
		"1")
			addbookmark
		;;
		"2")
			delbookmark
		;;
		*)
			cur_url=$(cat ~/.mybrowser/bookmark|sed -n "$((bmselect-2))"'p')
			gotopage
		;;
	esac
}
addbookmark(){
	echo "$cur_url">>~/.mybrowser/bookmark
	
}
delbookmark(){
	bookmark=$(cat ~/.mybrowser/bookmark|awk 'BEGIN{num=1}{print num" \""$0"\""}{num=num+1}')

	bmselect=$(echo $bookmark|xargs dialog --menu "Select Bookmark which you want to delete" 200 100 10 3>&1 1>&2 2>&3 3>&-)
	if [ $? -eq 1 -o $? -eq 255 ]; then
		return
	fi

	sed -i "" "$bmselect""d" ~/.mybrowser/bookmark
	
}
showhelp(){
	dialog --textbox ~/.mybrowser/helppage 200 100
}
checkcmd(){
	cmd=$(echo $cmd | sed  's/^ *| *$//g')
	case $cmd in
		"/D")
			findlink -download
		;;
		"/S")
			source
			gotopage "norecord"
		;;
		"/L")
			findlink -link
		;;
		"/B")
			bookmark
		;;
		"/H")
			showhelp
		;;
		"/pp")
			if [ $history_index -eq 1  ]; then
				dialog --msgbox "No previous page!" 200 100
			else
				history_index=$((history_index-1))
				cur_url=$(cat ~/.mybrowser/.browse_history|sed -n $history_index"p")
				gotopage "norecord"				
			fi
		;;
		"/np")
			all_index=$(cat ~/.mybrowser/.browse_history|wc -l)
			if [ $history_index -eq $all_index  ]; then
				dialog --msgbox "No next page!" 200 100
			else
				history_index=$((history_index+1))
				cur_url=$(cat ~/.mybrowser/.browse_history|sed -n $history_index"p")
				gotopage "norecord"
			fi

		;;
		*)
			echo $cmd|grep -E "^ *!">/dev/null
			# have ! it's cmd
			if [ $? -eq 0 ]; then
				cmd=$(echo $cmd|sed 's/^ *! *\$ *{//g'|sed 's/} *$//g')
				file=$(mktemp)
				eval $cmd>$file 2>>~/.mybrowser/error
				dialog --textbox $file 200 100
				rm $file
				gotopage "norecord"
				
			# url or garbage
			else
				echo $cmd|grep "^/">>/dev/null
				if ! [ $? -eq 0 ]; then
					tempurl=$cmd
					checkurl
				else
					dialog --msgbox "Invalid Command\nTry /H for help Messages" 200 100

				fi

			fi
		;;
	esac
}
checkurl(){
	echo $tempurl|grep -q  "://"
	if [ $? -ne 0 ]; then
		tempurl="http://"$tempurl
	fi
	teg=$(curl -o /dev/null -s -w "%{http_code}\n" "$tempurl")
	
	#URL fail
	if [ $teg -eq "000"  ]; then
		dialog --msgbox "Page not exists or Wrong input" 200 100
	else
		cur_url=$tempurl
		gotopage
	fi
}

_main(){
	echo "">~/.mybrowser/.browse_history
	checkterms
	gotopage
	while [ ""=="" ] ; do
		inputpage
	done

}
_main
