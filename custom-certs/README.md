# Example HTTPS Server with custom certificates

This is to just use the image provided by this application from quay.io and overlay custom certificates on top of it to deploy it and show secure routes similar to how it was originally done by the author.
So the only thing being added here are the custom certifcates and then using S2I to rebuilt the image to have the added custom SSL certificates. 

To deploy the application with secure routes use the following steps

### Generate Custom Self Signed Certs
If you don't already have your own custom certs readily available to use you can generate them using the following steps.   
This step is not required if you already have your custom certificate assests. 

1. Clone the repository container the self signed certificate playbook from https://github.com/cadjai/generate-custom-certificates.git
2. Change into the cloned custom certificates playbook directory 
3. Update the variables to reflect your desired common name,  service, and set the certs_dir to point to the custom-certs directory here ...
4. Run the playbook to generate the self signed CA and certificates using `ansible-playbook create-self-signed-certs.yml`
5. Verify that the appropriate certificates were generated into the custom-certs directory


### Build the application with S2i
To build the updated container image containing the pki certificate and key using S2I use the following steps

1. Login to the cluster
2. Create a new project using `oc new-project <project-name>` or change into an existing project using `oc project <project-name>`
3. Ensure you are back into the cloned examplehttpsserver application directory
4. Setup the S2i build of the application using the following command `oc new-build -D $'FROM quay.io/markd/testserver:latest\nADD localhost.crt /app/localhost.crt\nADD localhost.key /app/localhost.key\nRUN chown 1001:0 /app/localhost*' --context-dir=custom-certs --to=image-registry.openshift-image-registry.svc:5000/testserver ` . Feel free to change the name of the application if desired
5. Build the container image with the SSL certificate overlaid inside using `oc start-build testserver --from-dir=custom-certs --follow`

Once the application is successfully build you should be able toi review the produced imagestream using `oc describe is $(oc get is --no-headers | grep testserver | awk '{print $1}')` to review the produce image.  

### Run the application
To run the updated container image containing the pki certificate and key use the following steps

1. Login to the cluster
2. Create a new project using `oc new-project <project-name>` or change into an existing project using `oc project <project-name>`
3. Ensure you are back into the cloned testserver application directory
4. Deploy the application using the following command `oc new-app --name=testserver --image-stream=testserver` . Feel free to change the name of the application if desired

Once the application is successfully build you should be able to review the various k8 objects like the deployment, service ...

### Create the Routes

Expose the various routes using the following commands

#### Create unsecure route

Create the default unsecure route using 
```
oc expose service testserver 
```  
Once the route is create you can retrieve the route using 
```
oc get route testserver -ojsonpath='{"http://"}{.spec.host}{"\n"}'
```   
You can now use your browser to navigate to the route or use curl to query the route. 

#### Create edge route

Create the edge route using 
```
oc create route edge testserver-edge --service=testserver --port=8080
```  
Once the route is create you can retrieve the route using 
```
oc get route testserver-edge -ojsonpath='{"https://"}{.spec.host}{"\n"}'
```   
You can now use your browser to navigate to the route or use curl to query the route. 

#### Create passthrough route 

Create the passthrough route using 
```
oc create route passthrough testserver-passthrough --service=testserver --port=8443
```  
Once the route is create you can retrieve the route using 
```
oc get route testserver-passthrough -ojsonpath='{"https://"}{.spec.host}{"\n"}'
```   
You can now use your browser to navigate to the route or use curl to query the route. 

#### Create reencrypt route

Create the reencrypt route using 
```
oc create route reencrypt testserver-reencrypt --service=testserver --port=8443 --dest-ca-cert=custom-certs/ca.crt
```  
Once the route is create you can retrieve the route using 
```
oc get route testserver-reencrypt -ojsonpath='{"https://"}{.spec.host}{"\n"}'
```  
You can now use your browser to navigate to the route or use curl to query the route.   

> : Warning **Note that to create the reencrypt route the only certificate attribute needed is the dest-ca-cert. If you set both the dest-ca-cert and the ca-cert you get the 'application not available' error.**

For the secure route generated above you can also add path and/or hostname to the command if needed. 
> : Warning If using path with reencrypt route on an OpenShift 4.10.x, ensure that the pod has TLS1.3 enabled. We have seen an issue where with path enabled the route stopped working and it took a lot of troubleshooting to get to the bottom of this. 
