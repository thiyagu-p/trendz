class RelianceSpecial

  def self.split
    transactions.lines.each do |line|
      date, symbol, action, quantity, price, brokerage = line.split(',')
      {RELIANCE:52.0,RCOM:38.7,RENVL:7.3,RCAPVL:1.3,RNRL:0.7}.each_pair do |key, value|
        puts "#{date},#{key},Buy,#{quantity},#{(price.to_f*value/100.0).round(2)},#{(brokerage.to_f*value/100.0).round(2)},Thiyagu,ICICI_Direct"
      end
      puts ''
    end
  end
end

def transactions
<<EOF
20050808,RELIANCE,Buy,21.0,718.1,139.72,Thiyagu,ICICI_Direct
20050824,RELIANCE,Buy,15.0,691.5,96.10,Thiyagu,ICICI_Direct
20051004,RELIANCE,Buy,14.0,800.0,103.77,Thiyagu,ICICI_Direct
20051006,RELIANCE,Buy,10.0,788.75,73.08,Thiyagu,ICICI_Direct
20051011,RELIANCE,Buy,10.0,788.95,73.10,Thiyagu,ICICI_Direct
20051013,RELIANCE,Buy,10.0,774.7,71.78,Thiyagu,ICICI_Direct
20051014,RELIANCE,Buy,10.0,765.35,70.91,Thiyagu,ICICI_Direct
20051019,RELIANCE,Buy,10.0,745.0,69.02,Thiyagu,ICICI_Direct
20051116,RELIANCE,Buy,20.0,813.7,150.78,Thiyagu,ICICI_Direct
20060106,RELIANCE,Buy,30.0,923.0,256.55,Thiyagu,ICICI_Direct
20060110,RELIANCE,Buy,30.0,901.4,250.54,Thiyagu,ICICI_Direct
20060112,RELIANCE,Buy,30.0,890.85,247.61,Thiyagu,ICICI_Direct
20060117,RELIANCE,Buy,30.0,920.75,255.92,Thiyagu,ICICI_Direct
20060117,RELIANCE,Buy,30.0,899.5,250.02,Thiyagu,ICICI_Direct
20060117,RELIANCE,Buy,30.0,904.35,251.36,Thiyagu,ICICI_Direct
EOF

end
