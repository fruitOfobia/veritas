module AdminHelper
  def admin_nav_link(label, path)
    active = current_page?(path)
    classes = [ "block rounded-lg px-3 py-2 font-medium transition-colors" ]
    classes << (active ? "bg-brand-500 text-white" : "text-ink-300 hover:bg-ink-800 hover:text-white")

    link_to label, path, class: classes.join(" ")
  end
end
