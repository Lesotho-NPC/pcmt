#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# file to be replaced
attribute="Attribute.orm.yml"
attribute_translation="AttributeTranslation.orm.yml"
attribute_group="AttributeGroup.orm.yml"
category="Category.orm.yml"
measurementInstaller="MeasurementInstaller.php"
# folder
folder_structure="../vendor/akeneo/pim-community-dev/src/Akeneo/Pim/Structure/Bundle/Resources/config/model/doctrine"
folder_enrichment_category="../vendor/akeneo/pim-community-dev/src/Akeneo/Pim/Enrichment/Bundle/Resources/config/doctrine/Category/"
folder_measurement_installer="../vendor/akeneo/pim-community-dev/src/Akeneo/Tool/Bundle/MeasureBundle/Installer/"


# Replace the old file with the new file
cp -v $DIR/$attribute $DIR/$folder_structure/$attribute && cp -v $DIR/$attribute_translation $DIR/$folder_structure/$attribute_translation && cp -v $DIR/$attribute_group $DIR/$folder_structure/$attribute_group && cp -v $DIR/$category $DIR/$folder_enrichment_category/$category && cp -v $DIR/$measurementInstaller $DIR/$folder_measurement_installer/$measurementInstaller
