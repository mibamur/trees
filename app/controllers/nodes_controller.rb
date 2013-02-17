class NodesController < ApplicationController

	def index
		@nodes = Node.all
		render 'index'
	end

	def destroy
		if request.xhr? 
			Node.find(params[:id]).destroy 
		end 
		render nothing: true
	end

	def update
		if request.xhr? 
			Node.find(params[:id]).update_attributes(params[:node])
		end 
		render nothing: true
	end

end
