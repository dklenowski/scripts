"""
Calculates disk sizes for preseed configurations.
"""


free = 10000
#free = 55834

# boot, /, swap
mininum = [ 50, 2000, 2048 ]
priority = [ 2000, 10000, 2048 ]
maximum = [ 100, 1000000000, 2048 ]

#mininum = [ 50, 300, 2000 ]
#priority = [ 2000, 1000, 10000 ]
#maximum = [ 100, 1024, 1000000000 ]

sz = len(mininum)

factor = []
for i in range(sz):
  factor.append(priority[i] - mininum[i])


print "factor: %s" % factor

ready = False
while not ready:
  minsum = sum(mininum)
  factsum = sum(factor)
  ready = True

  for i in range(sz):
    x = float(mininum[i]) + float(free-minsum) * float(factor[i])/float(factsum)
    if x > maximum[i]:
      x = maximum[i]
    if x != mininum[i]:
      ready = False
      mininum[i] = x

print "Resultant partition table: %s = %d" % (mininum, sum(mininum))

