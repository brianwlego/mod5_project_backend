class Api::V1::QuizzesController < ApplicationController
  skip_before_action :authorized, only: [:index, :show]

  def index
    paginate Quiz.unscoped, per_page: 30
  end

  def show
    quiz = Quiz.find(params[:id])
    if current_user
      fav_quiz = FavQuiz.find_by(user_id: current_user.id, quiz_id: quiz.id)
    end
    render json: { quiz: QuizSerializer.new(quiz), fav_quiz: fav_quiz }
  end

  def create
    quiz = Quiz.create(quiz_params)
    if params[:img] != ''
      quiz.save_image(params[:img], quiz)
    end
    quiz.user_created_id = current_user.id
    quiz.save
    if quiz.valid?
      render json: { quiz: QuizSerializer.new(quiz) }, status: :accepted
    else
      render json: { error: "Failed to create quiz."}, status: :not_acceptable
    end
  end

  def update
    quiz = Quiz.find(params[:id])
    quiz.update(quiz_params)
    if params[:newimg] != ''
      quiz.save_image(params[:newimg], quiz)
    end

    if quiz.valid?
      render json: { quiz: QuizSerializer.new(quiz) }, status: :accepted
    else
      render json: { error: "Failed to update quiz" }, status: :not_acceptable
    end
  end

  def destroy
    quiz = Quiz.find(params[:id])
    quiz.questions.each{|question| question.destroy}
    quiz.destroy
    if !quiz.save
      render json: { success: "Quiz deleted" }, status: :accepted
    else
      render json: { error: "Failed to delete quiz" }, status: :not_acceptable
    end
  end

  def favorite
    fav_quiz = FavQuiz.create(quiz_id: params[:quiz_id], user_id: current_user.id)
    if fav_quiz.valid?
      render json: { fav_quiz: fav_quiz }, status: :accepted
    else
      render json: { error: "Failed to favorite quiz" }, status: :not_acceptable
    end
  end

  def unfavorite
    fav_quiz = FavQuiz.find_by(user_id: current_user.id, quiz_id: params[:quiz_id])
    fav_quiz.destroy
    if !fav_quiz.save
      render json: { success: "Deleted fav_quiz"}, status: :accepted
    else
      render json: { error: "Failed to unfavorite quiz"}, status: :not_acceptable
    end
  end

  def create_score
    score = Score.create(user_id: current_user.id, quiz_id: params[:quiz_id], percent: params[:score][:percent], right: params[:score][:right], wrong: params[:score][:wrong], chosen: params[:score][:chosen])
    if score.valid?
      render json: { score: ScoreSerializer.new(score) }, status: :accepted
    else
      render json: { error: "Failed to create new score"}, status: :not_acceptable
    end
  end

  def destroy_score

  end


  private

  def quiz_params
    params.require(:quiz).permit(:category, :title)
  end

end
