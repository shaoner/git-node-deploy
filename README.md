Advanced Git Node Deployment
==============

## Guidelines

### Content

- bin/ contains scripts used by the post-receive hook (this is splitted because of sudo)
- hooks/ contains the git hook used after a push
- upstart/ contains the upstart script to put in /etc/init/

### Explanations

- node is the Node.js user
- myapp is the name of your node app
- myapp-main is the main instance of your node app on the remote server
- myapp-spare is the same as myapp-main, except it runs at a different port

Both myapp-main / myapp-spare run as clusters **in production** through Nginx as a proxy. So myapp-main and myapp-spare differ only by the port.
During the process, one of the cluster is stopped and updated, while the other one is still running.
This actually prevent any disconnection (if everything goes fine).

On the other hand, myapp-staging runs only as a test before pushing to production.

When you push to staging, myapp-main is updated on the server side and myapp-staging is started.
When you push to master, myapp-staging is stopped. Then myapp-main is stopped while it is updating and restarted.
Finally, myapp-spare is also stopped while it is updated and restarted.

### Here we assume

- /srv/http/myapp/app/main is the main git repository
- /srv/http/myapp/app/spare is the spare git repository
- /srv/http/myapp/app/staging is the staging git repository
- /srv/http/myapp/static/index is the directory where static files are stored in production
- /srv/http/myapp/static/staging/index is the directory where static files are stored in staging
- /etc/node/myapp/ contains main.json, spare.json and staging.json which are configuration files for myapp

### The process in detail

0. You rebase your private devel branch on the main devel branch
1. You develop and fix things in your private devel branch
2. When your private devel branch is ready you push it to the origin
3. The git integrator (maybe you) takes care about merging all private devel branch into the devel branch. He can fix conflicts, and makes sure everything fits well.
4. If it is OK, he merges the devel branch into the staging branch and pushes it to the origin.
4. On the origin' side, the git hook:
  - stops myapp-staging if running (but it should not)
  - updates myapp-staging (git / npm / grunt)
  - start myapp-staging
5. He can now tests myapp directly online. If it goes wrong, go back to 0.
6. Assuming everything is OK, he merges the staging branch in the master branch and pushes it to the origin
8. On the origin' side, the git hook:
  - stops myapp-staging
  - stops myapp-main
  - updates myapp-main (git / npm / grunt)
  - restarts myapp-main
  - stops myapp-spare
  - updates myapp-spare (git / npm / grunt)
  - restarts myapp-spare

### Notes about the JSON configuration

In my case, I am able to provide the configuration file through "-c /path/to/config.json" or through NODE_CONFIG="/path/to/config.json"
It allows me to handle different configurations and to share them between grunt / myapp / etc.
