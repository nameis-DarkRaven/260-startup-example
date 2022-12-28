while getopts k:h: flag
do
    case "${flag}" in
        k) key=${OPTARG};;
        h) hostname=${OPTARG};;
    esac
done

if [[ -z "$key" || -z "$hostname" ]]; then
    printf "\nMissing required parameter.\n"
    printf "  syntax: deploy.sh -k <pem key file> -h <hostname>\n\n"
    exit 1
fi

service=startup

printf "\n----> Deploying $service application to $hostname with $key\n"


# Step 1
printf "\n----> Build the distribution package\n"
rm -rf dist
pushd ui
npm run build
popd
mkdir dist
mv ui/dist dist/public
printf "%s" $(date +%F-%T) > version.txt
cp *.js *.json version.txt dist

# Step 2
printf "\n----> Clearing out previous distribution on the target\n"
ssh -i $key ubuntu@$hostname << ENDSSH
rm -rf services/${service}
mkdir -p services/${service}
ENDSSH

# Step 3
printf "\n----> Copy the distribution package to the target\n"
scp -r -i $key dist/* ubuntu@$hostname:services/$service

# Step 4
printf "\n----> Deploy the service on the target\n"
ssh -i $key ubuntu@$hostname << ENDSSH
cd services/${service}
npm install
pm2 restart ${service}
ENDSSH

# Step 5
printf "\n----> Removing local copy of the distribution package\n"
rm -rf dist
