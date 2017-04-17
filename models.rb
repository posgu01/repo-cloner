class Milestone
    attr_accessor :title, :state, :description, :due_on, :number
end

class Label
    attr_accessor :name, :color
end

class Issue
    attr_accessor :title, :body, :assignees, :milestone, :labels
end
