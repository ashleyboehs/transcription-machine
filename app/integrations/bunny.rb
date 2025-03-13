class Bunny
  attr_reader :client

  def initialize(access_key: nil, library_id: nil)
    access_key ||= Rails.application.credentials.bunny_access_key
    library_id ||= Rails.application.credentials.bunny_library_id

    @client = BunnyClient.new(access_key: access_key, library_id: library_id)
  end

  def sync(page: 1)
    page = 0
    loop do
      page += 1
      response = client.get("/videos?page=#{page}")
      response[:items].each{ sync_video(_1) }
      next_page = response[:currentPage] * response[:itemsPerPage] < response[:totalItems]
      break unless next_page
      page += 1
    end
  end

  def sync_video(item)
    video = Video.where(guid: item[:guid]).first_or_initialize
    video.update(
      library_id: item[:videoLibraryId],
      title: item[:title],
      captions: item[:captions].any?{_1[:label] == "English" }
    )
  end
end
