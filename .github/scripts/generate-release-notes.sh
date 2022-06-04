#!/bin/bash

touch release.md

echo "# Release Notes $VERSIONTAG" > release.md

echo "\`\`\`" >> release.md
for files in $(find . -name "*.tar.gz"); do sha256sum "$files" >> release.md; done
echo "\`\`\`" >> release.md

echo "###### udroid tarballs ( intended to use with termux proot environment )" >> release.md
