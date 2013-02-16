class NodesController < ApplicationController
	def index
		@nodes = Node.all
		render 'index'
	end
end
