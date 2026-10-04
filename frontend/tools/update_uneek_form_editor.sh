#!/bin/bash

set -e

cd ~/node_modules/uneek_form_editor
yarn build
cd -

cp -r ~/node_modules/uneek_form_editor/dist frontend/node_modules/uneek_form_editor

rm -f frontend/tmp/cache/webpacker/last-compilation-digest-development

./frontend/exec rake webpacker:compile

#touch frontend/app/hyperstack/components/settings/schema/klasses/forms.rb
