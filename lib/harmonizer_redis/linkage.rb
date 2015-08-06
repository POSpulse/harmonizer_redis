class Linkage < BaseObject
  attr_accessor :foreign_id, :content

  def initialize(params)
    @foreign_id = params[:foreign_id]
    @content = params[:content]
  end

end