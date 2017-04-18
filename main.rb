require 'unirest'
require 'pp'

require_relative 'models'
require_relative 'puts'
require_relative 'error_messages'

Print.prompt "Enter your GitHub username: "
username = gets.strip

Print.prompt "Enter your GitHub personal access token: "
personal_token =  gets.strip
#"9eba99280b103d8e389efb1d718be4d611be283e"

Print.prompt "Enter the project you want to clone from: "
from = gets.strip
#from = "posgu01/dummy-repo"

Print.prompt "Enter the project you want to clone to: "
to = gets.strip
#to = "posgu01/dummy-repo-2"

baseUrl = "https://api.github.com"

# Get All Labels

labelsResponse = Unirest.get "#{baseUrl}/repos/#{from}/labels",
                             auth: { username: username, password: personal_token }

if labelsResponse.code >= 300
    Error.retrieving_asset("labels", labelsResponse.code)
    exit 1
end

labels = []
labelsResponse.body.each do |label|
    newLabel = Label.new
    newLabel.name = label["name"]
    newLabel.color = label["color"]
    labels << newLabel
end

# Get All Milestones

milestoneResponse = Unirest.get "#{baseUrl}/repos/#{from}/milestones",
                                auth: { username: username, password: personal_token }

if milestoneResponse.code >= 300
    Error.retrieving_asset("milestones", milestoneResponse.code)
    exit 1
end

milestones = []
milestoneResponse.body.each do |milestone|
    newMilestone = Milestone.new
    newMilestone.title = milestone["title"]
    newMilestone.state = milestone["state"]
    newMilestone.description = milestone["description"]
    newMilestone.due_on = milestone["due_on"]
    newMilestone.number = nil
    milestones << newMilestone
end

# Get All Issues

issueResponse = Unirest.get "#{baseUrl}/repos/#{from}/issues",
                            auth: { username: username, password: personal_token }

if issueResponse.code >= 300
    Error.retrieving_asset("issues", issueResponse.code)
    exit 1
end

issues = []
issueResponse.body.each do |issue|
    newIssue = Issue.new
    newIssue.title = issue["title"]
    newIssue.body = issue["body"]
    newIssue.assignees = []
    newIssue.labels = issue["labels"].map { |label| label["name"] }

    if issue["milestone"] != nil
        newIssue.milestone = issue["milestone"]["title"]
    else
        newIssue.milestone = nil
    end
    issues << newIssue
end

# Add labels into new repo

labels.each do |label|
    Print.info "Migrating label '#{label.name}' to #{to}..."

    params = {}
    params[:name] = label.name
    params[:color] = label.color

    labelCreationResponse = Unirest.post "#{baseUrl}/repos/#{to}/labels",
                                    auth: { username: username, password: personal_token },
                                    parameters: params.to_json

    if labelCreationResponse.code >= 300
        if labelCreationResponse.code == 422
            Puts.warn "Warning!"
            Error.asset_exists("label")
        else
            Puts.error "Failure!"
            Error.creating_asset("label", labelCreationResponse.code)
        end
    else
        Puts.info "Success!"
    end
end

# Add milestones into new repo

existingMilestoneResponse = Unirest.get "#{baseUrl}/repos/#{to}/milestones",
                                auth: { username: username, password: personal_token }

if existingMilestoneResponse.code >= 300
    Error.retrieving_asset("milestones", milestoneResponse.code)
    exit 1
end

existingMilestones = []
existingMilestoneResponse.body.each do |milestone|
    newMilestone = Milestone.new
    newMilestone.title = milestone["title"]
    newMilestone.state = milestone["state"]
    newMilestone.description = milestone["description"]
    newMilestone.due_on = milestone["due_on"]
    newMilestone.number = milestone["number"]
    existingMilestones << newMilestone
end

milestones.each do |milestone|
    Print.info "Migrating milestone '#{milestone.title}' to #{to}..."

    params = {}
    params[:title] = milestone.title
    params[:state] = milestone.state
    params[:description] = milestone.description
    params[:due_on] = milestone.due_on

    milestoneCreationResponse = Unirest.post "#{baseUrl}/repos/#{to}/milestones",
                                        auth: { username: username, password: personal_token },
                                        parameters: params.to_json

    if milestoneCreationResponse.code >= 300
        if milestoneCreationResponse.code == 422
            Puts.warn "Warning!"
            Error.asset_exists("milestone")
            if existingMilestones.select { |ms| ms.title == milestone.title } != []
                milestone.number = existingMilestones.select {|ms| ms.title == milestone.title}.first.number
            else
                Puts.error "Unable to retrieve unique identifier for milestone '#{milestone.title}'. Aborting..."
                exit 1
            end
        else
            Puts.error "Failure!"
            Error.create_asset("milestone", milestoneCreationResponse.code)
        end
    else
        milestone.number = milestoneCreationResponse.body["number"]
        Puts.info "Success!"
    end
end

# Add issues into new repo

#Github expects the milestone to be a number, not a title. So let's go get the number.

issues.reverse.each do |issue|
    Print.info "Migrating issue '#{issue.title}' to #{to}..."

    issue.milestone = milestones.select{|ms| ms.title == issue.milestone}.first

    params = {}
    params[:title] = issue.title
    params[:body] = issue.body
    params[:assignees] = issue.assignees
    params[:milestone] = issue.milestone ? issue.milestone.number : nil
    params[:labels] = issue.labels


    issueCreationResponse = Unirest.post "#{baseUrl}/repos/#{to}/issues",
                                    auth: { username: username, password: personal_token },
                                    parameters: params.to_json

    if issueCreationResponse.code >= 300
        if issueCreationResponse.code == 422
            Puts.warn "Warning!"
            Error.asset_exists("issue")
        else
            Puts.error "Failure!"
            Error.creating_asset("milestone", issueCreationResponse.code)
        end
    else
        Puts.info "Success!"
    end
end
