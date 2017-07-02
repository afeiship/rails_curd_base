require 'rails'

module RailsCurdBase

  module CurdActions

    def index
      @items = CurdHelper.model_class.all
    end

    def show
      @item = CurdHelper.model_class.find(params[:id])
    end

    def edit
      @item = CurdHelper.model_class.find(params[:id])
    end

    def new
      @item = CurdHelper.model_class.new
    end

    def create
      @item = CurdHelper.model_class.new(item_params)
      if @item.save
        redirect_to @item, notice: CurdHelper.messages[:create]
      else
        render :new
      end
    end

    def update
      @item = CurdHelper.model_class.find(params[:id])
      if @item.update(item_params)
        redirect_to @item, notice: CurdHelper.messages[:update]
      else
        render :edit
      end
    end

    def destroy
      @item = CurdHelper.model_class.find(params[:id])
      @item.destroy
      redirect_to CurdHelper.model, notice: CurdHelper.messages[:destroy]
    end


    private
    def set_item
      @item = CurdHelper.model_class.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def item_params
      params.require(CurdHelper.model).permit(CurdHelper.fields)
    end
  end

end