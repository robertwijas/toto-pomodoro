module Toto::Pomodoro
  
  @@label_synonyms = []
  
  class << self
    attr_accessor :label_synonyms
  end
  
  def self.standard_label label
    label_synonyms.each do
      |synonyms|
      return synonyms.first if synonyms.find_index(label)
    end
    
    return label
  end
  
  def self.standard_month_date date
    date - date.day + 1 
  end

  def self.pomodoro_count articles
    articles.map {|a| a.pomodoros.count}.inject{|sum,x| sum + x}
  end

  # returns [count, average, data]
  def self.last_30_days articles
    first_day = Date.today - 30
    articles = articles.select {|a| a[:date] > first_day}
    (count_and_daily_average articles) << (article_count_stats_data articles)
  end

  def self.count_and_daily_average articles
    days = []
    pomodoro_count = 0
    
    articles.each do
      |a|
      pomodoro_count += a.pomodoros.count
      if a.pomodoros.count
        days << a[:date]
      end
    end
    
    days.uniq!
    
    [pomodoro_count, (days.empty? ? 0 : pomodoro_count / days.count.to_f)]
  end

  def self.daily_average articles
    (count_and_daily_average articles).last
  end

  def self.monthly_stats_data articles
    months = {}
    labels = []

    articles.each do
      |a|
      date = standard_month_date a[:date]
      month_data = months[date] || {}

      a.pomodoros.each do
        |label|
        label = standard_label label
        month_data[label] = month_data[label].to_i + 1
        labels << label
      end

      months[date] = month_data
    end

    labels.uniq!
    labels.sort!

    months_array = months.keys.sort
    data = []

    months_array.each do
      |m|
      labels.each do
        |l|
        # choose data object for update
        d = data.select {|x| x['name'].eql?(l)}.first

        if d.nil?
          d = {'name' => l, 'data' => []}
          data << d
        end

        d['data'] << (months[m][l].nil? ? 0 : months[m][l])
      end
    end

    return months_array, data
  end

  def self.article_count_stats_data articles
    data = articles.reverse.collect do
      |a|
      {:y => a.pomodoros.count, :url => a.url, :title => a.title, :x => (Time.parse(a[:date].to_s).to_i * 1000)}
    end

    return data
  end

  def self.label_pomodoros articles
    data = {}
    articles.each do
      |a|
      a.pomodoros.each do
        |l|
        l = standard_label l
        data[l] = data[l].to_i + 1
      end
    end

    return data
  end

  def self.labels_stats_data articles
    data = label_pomodoros articles
    tags = data.keys.sort

    pomodoros = []
    tags.each do
      |t|
      pomodoros << data[t]
    end

    return tags, pomodoros
  end
  
  def self.filter_articles(articles, env)
    request = Rack::Request.new env
    query = request.params['pomodoro'] if request
    
    if query
      standard_label = standard_label query
      articles.select {|a| (a.pomodoros.map {|p| standard_label p}).find_index(standard_label)}
    else
      articles
    end
  end
  
  def self.pomodoro_labels_html article
    html = ''
    labels = article.pomodoros_unique

    if not labels.empty?
      labels.each {|l| html << "<li><a href=\"/archives?pomodoro=#{l}\">#{l}</a></li>"}
      html = "<ul class=\"pomodoro-labels\">#{html}</ul>"
    end
    
    return html
  end
  
end

class Toto::Article
  
  def pomodoros
    labels = self[:pomodoros] ? self[:pomodoros].to_s.split : []
    pomodoros = []
    
    labels.each do
      |l|
      if l.match('^.*\*\d+$')
        p, c = l.split('*')
        c.to_i.times {|i| pomodoros << p}
      else
        pomodoros << l
      end
    end
    
    return pomodoros
  end
  
  def pomodoros_unique
    self.pomodoros.map {|p| Toto::Pomodoro.standard_label p}.uniq
  end

end
