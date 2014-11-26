#!/usr/bin/env ruby

require "slack-notifier"

# Using dotenv for debug in local
#require "dotenv"
#Dotenv.load

webhook_url = ENV["WERCKER_PRETTY_SLACK_NOTIFY_WEBHOOK_URL"]
channel     = ENV["WERCKER_PRETTY_SLACK_NOTIFY_CHANNEL"]
username    = ENV["WERCKER_PRETTY_SLACK_NOTIFY_USERNAME"]
$build_success_message = ENV["WERCKER_PRETTY_SLACK_NOTIFY_BUILD_SUCCESS_MESSAGE"] || ""
$build_failed_message = ENV["WERCKER_PRETTY_SLACK_NOTIFY_BUILD_FAILED_MESSAGE"] || ""
$deploy_success_message = ENV["WERCKER_PRETTY_SLACK_NOTIFY_DEPLOY_SUCCESS_MESSAGE"] || ""
$deploy_failed_message = ENV["WERCKER_PRETTY_SLACK_NOTIFY_DEPLOY_FAILED_MESSAGE"] || ""

abort "Please specify the your slack webhook url" unless webhook_url
username = "Wercker"                              unless username

# See for more details about environment variables that we can use in our steps
# http://devcenter.wercker.com/articles/steps/variables.html
git_owner  = ENV["WERCKER_GIT_OWNER"]
git_repo   = ENV["WERCKER_GIT_REPOSITORY"]
app_name   = "#{git_owner}/#{git_repo}"
app_url    = ENV["WERCKER_APPLICATION_URL"]
build_url  = ENV["WERCKER_BUILD_URL"]
git_commit = ENV["WERCKER_GIT_COMMIT"]
git_branch = ENV["WERCKER_GIT_BRANCH"]
started_by = ENV["WERCKER_STARTED_BY"]

deploy_url        = ENV["WERCKER_DEPLOY_URL"]
deploytarget_name = ENV["WERCKER_DEPLOYTARGET_NAME"]

def deploy?
  ENV["DEPLOY"] == "true"
end

def build_message(app_name, app_url, build_url, git_commit, git_branch, started_by, status)
  m = status == "failed" ? $build_failed_message : $build_success_message
  "#{m}\n[[#{app_name}](#{app_url})] [build(#{git_commit[0,8]})](#{build_url}) of #{git_branch} by #{started_by} #{status}"
end

def deploy_message(app_name, app_url, deploy_url, deploytarget_name, git_commit, git_branch, started_by, status)
  m = status == "failed" ? $deploy_failed_message : $deploy_success_message
  "#{m}\n[[#{app_name}](#{app_url})] [deploy(#{git_commit[0,8]})](#{deploy_url}) of #{git_branch} to #{deploytarget_name} by #{started_by} #{status}"
end

def icon_url(status)
  #"https://github.com/wantedly/step-pretty-slack-notify/raw/master/icons/#{status}.jpg"
  "https://s3-us-west-2.amazonaws.com/slack-files2/bot_icons/2014-11-12/2992212676_48.png"
end

def username_with_status(username, status)
  username
  #"#{username} #{status.capitalize}"
end

notifier = Slack::Notifier.new(
  webhook_url,
  username: username_with_status(username, ENV["WERCKER_RESULT"])
)

message = deploy? ?
  deploy_message(app_name, app_url, deploy_url, deploytarget_name, git_commit, git_branch, started_by, ENV["WERCKER_RESULT"]) :
  build_message(app_name, app_url, build_url, git_commit, git_branch, started_by, ENV["WERCKER_RESULT"])

notifier.channel = '#' + channel if channel

res = notifier.ping(
  message,
  icon_url: icon_url(ENV["WERCKER_RESULT"])
)

case res.code
when "404" then abort "Webhook url not found."
when "500" then abort res.read_body
else puts "Notified to Slack #{notifier.channel}"
end
