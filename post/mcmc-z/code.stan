data {
  int<lower=0> K;
} 
parameters {
  vector[K] x;
} 
model {
  x ~ normal(0, 1);
}
