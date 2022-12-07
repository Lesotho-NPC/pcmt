#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# file to be replaced
oldFile_attribute="Attribute.orm.yml"
oldFile_attribute_translation="AttributeTranslation.orm.yml"

# new file
newFile_attribute="Attribute.orm.yml"
newFile_attribute_translation="AttributeTranslation.orm.yml"
# folder
folder="../vendor/akeneo/pim-community-dev/src/Akeneo/Pim/Structure/Bundle/Resources/config/model/doctrine"


# Replace the old file with the new file
cp -v $DIR/$newFile_attribute $DIR/$folder/$oldFile_attribute && cp -v $DIR/$newFile_attribute_translation $DIR/$folder/$oldFile_attribute_translation
