#!/bin/bash

cwd=$(pwd)

cd ~/Development
if [ ! -d "AEMTransformRules" ]; then
	mkdir AEMTransformRules
fi
cd AEMTransformRules

# Copy class AEMTransformRulesGenerator
if [ ! -f "AEMTransformRulesGenerator.st" ]; then
	cp "$cwd/AEMTransformRulesGenerator.st" "$(pwd)"
fi

# Get script arguments.
repository=${1:-"http://www.smalltalkhub.com/mc/ObjectProfile/GraphET2/main"} # Take Roassal3 as default if nothing has been provided.
project_name=$(echo $repository | sed "s/http:\/\/www.smalltalkhub.com\/mc\/[a-zA-Z0-9]*\///" | sed "s/\/main//")
dir_name="AEMRules-$project_name"
current_date=$(date +%Y-%m-%d)
echo "Creating APIEvolutionMiner rules for project '$project_name' in folder '$(pwd)/$dir_name' from repository '$repository'."

if [ ! -d $dir_name ]; then
	mkdir $dir_name
fi
cd $dir_name

#API_EVOL_MINER=APIEvolutionMiner

if [ ! -d "pharo-vm" ]; then
	echo "Downloading latest Pharo VM including sources. Open the URL 'get.pharo.org/vm' in browser for more information."
	curl --silent get.pharo.org/vm | bash
fi

if [ ! -f "APIEvolutionMiner-Jet.image" ]; then
	echo "Downloading APIEvolutionMiner-Jet image."
	curl --silent --insecure -o APIEvolutionMiner-Jet.zip https://ci.inria.fr/rmod/view/MinedRules/job/APIEvolutionMiner-Jet/lastSuccessfulBuild/artifact/APIEvolutionMiner-Jet.zip
	unzip -o APIEvolutionMiner-Jet.zip
fi

if [ ! -f "$project_name-Monitoring.image" ]; then
	echo "Running pharo with downloaded image and saving it as new image."
	./pharo APIEvolutionMiner-Jet.image save "$project_name-Monitoring"
fi

if [ ! -d "latestMczFiles" ]; then
	echo "Making directories for extracted source code changes."
	mkdir latestMczFiles
fi
if [ ! -d "latestSourceCodeChanges" ]; then
	mkdir latestSourceCodeChanges
fi

# Download existing dataset and sourceCodeChanges.
#curl --silent --insecure -o dataset https://ci.inria.fr/rmod/view/MinedRules/job/Roassal-Monitoring/lastSuccessfulBuild/artifact/dataset
#curl --silent --insecure -o ourMczFiles https://ci.inria.fr/rmod/view/MinedRules/job/Roassal-Monitoring/lastSuccessfulBuild/artifact/ourMczFiles
#curl --silent --insecure -o sourceCodeChanges.zip https://ci.inria.fr/rmod/view/MinedRules/job/Roassal-Monitoring/lastSuccessfulBuild/artifact/sourceCodeChanges.zip
#unzip sourceCodeChanges.zip

if [ ! -f "dataset" ]; then
  touch dataset
fi
if [ ! -f "ourMczFiles" ]; then
  touch ourMczFiles
fi
if [ ! -d "sourceCodeChanges" ]; then
  mkdir sourceCodeChanges
fi

# Get latest source code changes
# Be aware, this part can take a long time (up to several hours) and downloads several MBs data.
# Increase the memory: add "AddressSpaceLimit=1536" to Pharo.ini file ("./pharo --memory 1536m" doesn't work).
lastLinePharoIni=$(tail -1 pharo-vm/Pharo.ini | head -1)
if [ ! $lastLinePharoIni = "AddressSpaceLimit=1536" ]; then
	echo "Increasing AddressSpaceLimit (memory) of Pharo VM to 1536."
	echo "AddressSpaceLimit=1536" >> pharo-vm/Pharo.ini
fi
echo "Downloading latest MCZ files. Be aware, this step can take a long time and downloads several MBs data."
#./pharo Roassal-Monitoring.image eval --save AEMRepositoryDownloader downloaLatestMczsForRoassal. AEMRepositoryDownloader importToRingHistoryAndExportAssociations.
./pharo "$project_name-Monitoring.image" eval --save AEMRepositoryDownloader downloaLatestMczsFor: "'$repository'".
echo "Importing ring history and getting latest source code changes. Be aware, this step can take a long time."
./pharo "$project_name-Monitoring.image" eval --save AEMRepositoryDownloader importToRingHistoryAndExportAssociations.

# The file latestDataset and the folder latestSourceCodeChanges should be created by the AEMRepositoryDownloader.
if [ -f "latestDataset" ]; then
	cp -u latestDataset dataset
fi
if [ -d "latestSourceCodeChanges" ]; then
	cp -r latestSourceCodeChanges/* sourceCodeChanges
fi

# Recreate sourceCodeChanges.zip with latest changes.
#zip -r sourceCodeChanges.zip sourceCodeChanges/
#7z a -tZIP sourceCodeChanges sourceCodeChanges/

echo "Exporting oneOneRules and generating AEMTransformRules."
# Create rules.csv export. See here: https://ci.inria.fr/rmod/view/MinedRules/job/Moose-Report/lastSuccessfulBuild/consoleFull
#./pharo APIEvolutionMiner-Jet.image eval --save AEMSystemHistoryImporter loadSystemHistory: "'$project_name'". AEMReport exportOneOneRules.
./pharo APIEvolutionMiner-Jet.image eval --save "'../AEMTransformRulesGenerator.st' asFileReference fileIn."
./pharo APIEvolutionMiner-Jet.image eval --save "Author fullName: '$(whoami)'. AEMSystemHistoryImporter loadSystemHistory: '$project_name'. AEMTransformRulesGenerator new generateRBTransformationRules: ((AEMEvidenceRanking new systemHistory: ((AEMReport exportOneOneRules) systemHistory)) oneOneRules). (RPackageOrganizer default packageNamed: #AEMTransformRules) fileOut."

if [ ! -d "report" ]; then
	mkdir report
fi
if [ -f "rules.csv" ]; then
	cp rules.csv report/$current_date"_rules.csv"
fi

# Download HTML and JS files for viewing rules.csv in browser. Not necessarily needed.
#curl --silent --insecure -o index.html https://ci.inria.fr/rmod/view/MinedRules/job/Moose-Report/lastSuccessfulBuild/artifact/report/index.html
#curl --silent --insecure -o jquery-1.10.1.min.js https://ci.inria.fr/rmod/view/MinedRules/job/Moose-Report/lastSuccessfulBuild/artifact/report/jquery-1.10.1.min.js
#curl --silent --insecure -o jquery.csv-0.71.js https://ci.inria.fr/rmod/view/MinedRules/job/Moose-Report/lastSuccessfulBuild/artifact/report/jquery.csv-0.71.js
#mv index.html jquery-1.10.1.min.js jquery.csv-0.71.js report/

# Clean up working folder.
#rm latestDataset
#rm -r latestSourceCodeChanges
#rm -r sourceCodeChanges

cd ..