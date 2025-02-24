Battle.select("count(*), (updated_at::date) as final_date").where(state: "final").group("final_date").order("final_date").map{|x| [x["final_date"], x["count"]]}.to_h
