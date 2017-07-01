require 'rails'

module RailsCurdBase
  module CurdHelper
    class << self
      attr_accessor :model
      attr_accessor :actions
    end


    # Static class:
    class Actions
    end

    class << Actions
      def index
        @items = CurdHelper.model.all
      end

      def show(params)
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

      def update(params)
        @item = CurdHelper.model.find(params[:id])
        if @item.update(item_params)
          redirect_to @item, notice: 'Post was successfully updated.'
        else
          render :edit
        end
      end

      def destroy(params)
        @item = CurdHelper.model.find(params[:id])
        @item.destroy
        redirect_to admin_posts_url, notice: 'Post was successfully destroyed.'
      end


      private
      def set_item(params)
        @item = CurdHelper.model.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def item_params
        if params[:action] == 'new'
          nil
        else
          params.require(CurdHelper.model).permit(:title, :content)
        end
      end
    end


    # public helpers
    def model(inValue)
      CurdHelper.model = inValue
    end

    def actions(inValue)
      CurdHelper.actions = inValue
    end
  end
end