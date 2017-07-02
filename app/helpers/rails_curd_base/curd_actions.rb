require 'rails'

module RailsCurdBase

  module CurdActions
    def index
      @items = CurdHelper.model.all
    end

    def show
      @item = CurdHelper.model.find(params[:id])
    end

    def edit
      @item = CurdHelper.model.find(params[:id])
    end

    def new
      @item = CurdHelper.model.new
    end

    def create
      @item = CurdHelper.model.new(item_params)
      if @item.save
        redirect_to @item, notice: 'Post was successfully created.'
      else
        render :new
      end
    end

    def update
      @item = CurdHelper.model.find(params[:id])
      if @item.update(item_params)
        redirect_to @item, notice: 'Post was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @item = CurdHelper.model.find(params[:id])
      @item.destroy
      redirect_to admin_posts_url, notice: 'Post was successfully destroyed.'
    end


    private
    def set_item
      @item = CurdHelper.model.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def item_params
      params.require(:admin_post).permit!
    end
  end

end