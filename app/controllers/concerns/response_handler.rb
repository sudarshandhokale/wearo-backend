module ResponseHandler
  extend ActiveSupport::Concern

  def success_response(data: {}, serializer: nil, status: :ok, meta: {})
    response_data = serializer ? render_serializer(data: data, serializer: serializer, meta: meta) : { data: data, meta: meta.presence }

    render json: {
      success: true,
      data: response_data[:data],
      meta: response_data[:meta]
    }, status: status
  end

  def error_response(error: {}, status: :unprocessable_entity)
    render json: {
      success: false,
      error: error
    }, status: status
  end

  private

  def render_serializer(data:, serializer:, meta: {})
    serialized_data = ActiveModelSerializers::SerializableResource.new(data, each_serializer: serializer)

    {
      data: serialized_data,
      meta: pagination_meta(data).merge(meta).presence
    }
  end

  def pagination_meta(data)
    return {} unless data.respond_to?(:current_page)

    {
      current_page: data.current_page,
      next_page: data.next_page,
      prev_page: data.prev_page,
      total_pages: data.total_pages,
      total_count: data.total_count
    }
  end
end
