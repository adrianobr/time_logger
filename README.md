# Redmine Time Logger (Modern UI Fork)

This is a fork of the Redmine Time Logger plugin, featuring a modernized interface and high-visibility status animations.

### What have been changed:

* **Modernized UI:** Overhauled CSS with high-visibility animations (Pulse for Idle/Paused, Shine for Running).
* **Improved Responsiveness:** Fixed layout issues for different zoom levels and compact top menus.
* **Redmine Compatibility:** Tested and verified on **Redmine 6.1.2.stable**.
* Plugin structure is overhauled
* Adapted to Rails 6
* Periodically ajax requests replaced with pure javascript timer
* Added functional tests

Preview:

![](https://github.com/user-attachments/assets/5de7f1a6-e347-40be-9ecb-5748cdef5c32)

## Install (Standard)

1. Clone the plugin to your redmine root directory/plugins

     ```
    git clone [https://github.com/johnjeffersoncm/time_logger.git](https://github.com/johnjeffersoncm/time_logger.git) redmine_directory/plugins/time_logger
     ```
2. Setup the database using the migrations

     ```
    bundle exec bin/rails redmine:plugins:migrate RAILS_ENV=production NAME=time_logger
     ```
3. Login to your Redmine install as an Administrator
4. Setup the 'log time' permissions for your roles
5. Enable a "Time tracking" module in the project settings
6. The link to the plugin should appear in the 'account' menu bar

## Install (Docker)

For Docker-based installations, follow these steps (replace `$SK` with your `SECRET_KEY_BASE` if required by your environment):

1. Clone the plugin to your local plugins folder or directly into the container.
2. Check for new dependencies:
     ```
    docker exec -it redmine bundle install
     ```
3. Run migrations:
     ```
    docker exec -it -e SECRET_KEY_BASE=$SK redmine bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=time_logger
     ```
4. **Precompile Assets** (Mandatory for the new UI and JS timer):
     ```
    docker exec -it -e SECRET_KEY_BASE=$SK redmine bundle exec rake assets:precompile RAILS_ENV=production
     ```
5. Restart the container:
     ```
    docker restart redmine
     ```

*Note: The `SECRET_KEY_BASE` variable is usually required in production environments to sign/encrypt session cookies. Check your specific Docker deployment if it's already defined.*

## Running tests

Inside your redmine root directory run command:

```
bundle exec bin/rails redmine:plugins:test RAILS_ENV=test NAME=time_logger
```

## Uninstall 

1. Clean up a database: 

     ```
    bundle exec bin/rails redmine:plugins:migrate RAILS_ENV=production NAME=time_logger VERSION=0
     ```
2. Delete plugin folder: 

     ```
    rm -rf <redmine_root>/plugins/time_logger
     ```
