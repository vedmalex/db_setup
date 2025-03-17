# TCP тест
echo '{"message":"test"}' | nc localhost 5000

# UDP тест
echo '{"message":"test"}' | nc -u localhost 5000
