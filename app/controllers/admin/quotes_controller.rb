module Admin
  class QuotesController < AdminController

    before_action :set_quote, only: [:show, :edit, :update, :destroy]

    def index
      @quotes = Quote.ordered
    end

    def show
    end

    def new
      @quote = Quote.new
    end

    def create
      @quote = Quote.new(quote_params)

      if @quote.save
        respond_to do |format|
          format.html { redirect_to admin_quotes_path, notice: "Quote was successfully created." }
          format.turbo_stream { flash.now[:notice] = "Quote was successfully created." } # Use flash#now because turbo stream doesn't redirect
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @quote.update(quote_params)
        # redirect_to admin_quotes_path, notice: "Quote was successfully updated."
        respond_to do |format|
          format.html { redirect_to admin_quotes_path, notice: "Quote was successfully updated." }
          format.turbo_stream { flash.now[:notice] = "Quote was successfully updated." }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @quote.destroy
      respond_to do |format|
        format.html { redirect_to admin_quotes_path, notice: "Quote was successfully destroyed." }
        format.turbo_stream { flash.now[:notice] = "Quote was successfully destroyed." }
      end
    end

    private

    def set_quote
      @quote = Quote.find(params[:id])
    end

    def quote_params
      params.require(:quote).permit(:name)
    end
  end
end
