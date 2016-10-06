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

alias dialog='dialog --title "browser"'
alias curlcheck='curl -o /dev/null -s -w "%{http_code}"'

home_url="http://google.com"
cur_url="http://nasa.cs.nctu.edu.tw"
cmd=""
bmselect=""
tempurl="google.com"

checkterms(){
	dialog --title "terms" --yesno "$(cat ~/.mybrowser/userterm)" 200 100

	if [ "$?" -eq 1 ]; then
		dialog --title "Apology" --msgbox "Sorry, you can't use this browser if you don't agree the user terms" 200 100
		exit
	fi
}
gotopage(){
	file=mktemp
	
	w3m -dump $cur_url>$file
	
	dialog --textbox $file 200 100
	rm $file
}
inputpage(){
	cmd=$(dialog --inputbox "$cur_url" 200 100 \
			3>&1 1>&2 2>&3 3>&-)
	if [ "$?" -eq 0 ]; then
		checkcmd
	else
		exit
	fi 
}
findlink(){
	
#	link=$(curl -skL $cur_url| grep -E "<a href"|cut -d'"' -f2 |awk -v url=$cur_url '{if( $0 ~ "^ */"){print url$0}
#		else if($0 ~ "^ ..")print $0} }'|awk 'BEGIN{num=1} {print num" \""$0"\""}{num=num+1}')
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
	# goto link
	if ["$link" -eq ""];then
		dialog --msgbox "No Links in this page" 200 100
		gotopage
		return
	fi
	if [ "$1" = "-link" ]; then
	
	#	echo $link
		linkselect=$(echo $link|xargs dialog --menu "Link:" 200 100 20 3>&1 1>&2 2>&3 3>&-)
		
		if [ $? -eq 1 -o $? -eq 255 ]; then
			gotopage
			return
		else
			cur_url=$(echo $link|cut -d'"' -f$((linkselect*2)))
			gotopage
			
		fi
	else
		if [ "$1" = "-download" ]; then
			linkselect=$(echo $link|xargs dialog --menu "Download:" 200 100 20 3>&1 1>&2 2>&3 3>&-)
			if [ $? -eq 1 -o $? -eq 255 ]; then
				gotopage
				return
			else
				down_url=$(echo $link|cut -d'"' -f$((linkselect*2)))
				wget -qP ~/Downloads/ "$down_url"	
				gotopage
			fi
		fi
	fi
}
source(){
#	dialog --textbox "$(w3m -dump_source "$cur_url")" 200 100
	file=mktemp
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
		gotopage
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
	cmd=$(echo $cmd | sed -r 's/^ *| *$//g')
	case $cmd in
		"/D")
			findlink -download
		;;
		"/S")
			source
			gotopage
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
		*)
			echo $cmd|grep "^!">/dev/null
			# have ! it's cmd
			if [ $? -eq 0 ]; then
				cmd="$(echo $cmd|sed 's/^ *! *\$ *{//g'|sed 's/} *$//g')"
				file=mktemp
				eval $cmd>$file 2>>~/.mybrowser/error
				dialog --textbox $file 200 100
				gotopage
				rm $file
				
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
	checkterms
	gotopage
	while [ ""=="" ] ; do
		inputpage
	done

}
_main
