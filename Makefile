skip:
	echo "Did you mean make pushup?"

pushup:
	git push
	git push --tags
	git checkout develop
	git merge main
	git push

