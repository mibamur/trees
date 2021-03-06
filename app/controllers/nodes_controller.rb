class NodesController < ApplicationController

  def index
    @nodes = Node.all
    respond_to do |format|
      format.html { render :index } 
      format.json { render json: Node.links_of(@nodes) }
    end
  end
  
  def create
    @node = Node.new name: "node", description: "node"
    if request.xhr?   
      render json: @node if @node.save 
    end 
  end

  def destroy
    if request.xhr? 
      Node.find(params[:id]).destroy 
    end 
    render nothing: true
  end

  def update
    if request.xhr? 
      if params[:node]
        Node.find(params[:id]).update_attributes(params[:node])
      elsif params[:connection]
        if params[:connection][:destroy] == 'true'
          Node.find(params[:connection][:from]).nodes.delete Node.find(params[:connection][:to])
        else 
          Node.find(params[:connection][:from]).nodes << Node.find(params[:connection][:to])
        end
      end 
    end 
    render nothing: true
  end

end
