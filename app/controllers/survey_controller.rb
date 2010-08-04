class SurveyController < ApplicationController
  def index
    @RandomQuestions = (1..Survey::TotalQuestions).sort_by{rand}
  end

  def submit
    values = params[:survey]
    return if values.nil?
    oSurvey = Survey.new(values)
    oSurvey.session_id = Session.current.id
    # Save the Survey answers
    oSurvey.save
  end
end