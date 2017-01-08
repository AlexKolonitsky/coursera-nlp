package org.kolonitsky.coursera.nlp;

/* File:      ViterbiRef.java
*
* The ViterbiRef algorithm in Java
* Author: Paul Fodor <pfodor@cs.sunysb.edu>
* Stony Brook University, 2007
* Python version: http://en.wikipedia.org/wiki/Viterbi_algorithm
*/

public class ViterbiRef {
    private static final String[] STATES = {"Rainy", "Sunny"};
    private static final String[] OBSERVATIONS = {"walk", "shop", "clean"};
    private static final double[] START_PROBABILITY = {0.6, 0.4};
    private static final double[][] TRANSITION_PROBABILITY = {{0.7, 0.3}, {0.4, 0.6}};
    private static final double[][] EMISSION_PROBABILITY = {{0.1, 0.4, 0.5}, {0.6, 0.3, 0.1}};

    private static class TNode {
        public double prob;
        public int[] vPath;
        public double vProb;

        public TNode(double prob, int[] vPath, double vProb) {
            this.prob = prob;
            this.vPath = copyIntArray(vPath);
            this.vProb = vProb;
        }
    }

    private static int[] copyIntArray(int[] ia) {
        int[] newIa = new int[ia.length];
        System.arraycopy(ia, 0, newIa, 0, ia.length);
        return newIa;
    }

    private static int[] copyIntArray(int[] ia, int newInt) {
        int[] newIa = new int[ia.length + 1];
        System.arraycopy(ia, 0, newIa, 0, ia.length);
        newIa[ia.length] = newInt;
        return newIa;
    }

    // forwardViterbi(OBSERVATIONS, STATES, START_PROBABILITY, TRANSITION_PROBABILITY, EMISSION_PROBABILITY)
    public static void forwardViterbi(String[] y, String[] X, double[] sp, double[][] tp, double[][] ep) {
        TNode[] T = new TNode[X.length];
        for (int state = 0; state < X.length; state++) {
            int[] intArray = new int[1];
            intArray[0] = state;
            T[state] = new TNode(sp[state], intArray, sp[state]);
        }

        for (int output = 0; output < y.length; output++) {
            TNode[] U = new TNode[X.length];
            for (int next_state = 0; next_state < X.length; next_state++) {
                double total = 0;
                int[] argMax = new int[0];
                double valMax = 0;
                for (int state = 0; state < X.length; state++) {
                    double prob = T[state].prob;
                    int[] v_path = copyIntArray(T[state].vPath);
                    double v_prob = T[state].vProb;
                    double p = ep[state][output] * tp[state][next_state];
                    prob *= p;
                    v_prob *= p;
                    total += prob;
                    if (v_prob > valMax) {
                        argMax = copyIntArray(v_path, next_state);
                        valMax = v_prob;
                    }
                }
                U[next_state] = new TNode(total, argMax, valMax);
            }
            T = U;
        }
        // apply sum/max to the final STATES:
        double total = 0;
        int[] argMax = new int[0];
        double valMax = 0;
        for (int state = 0; state < X.length; state++) {
            double prob = T[state].prob;
            int[] v_path = copyIntArray(T[state].vPath);
            double v_prob = T[state].vProb;
            total += prob;
            if (v_prob > valMax) {
                argMax = copyIntArray(v_path);
                valMax = v_prob;
            }
        }

        System.out.print(" Probability of the state:" + total + ".\n ViterbiRef path: [");
        for (int anArgMax : argMax) {
            System.out.print(STATES[anArgMax] + ", ");
        }
        System.out.println("].\n Probability of the whole system: " + valMax);
    }

    public static void main(String[] args) throws Exception {
        System.out.print("\nStates: ");
        for (String state : STATES) {
            System.out.print(state + ", ");
        }
        System.out.print("\n\nObservations: ");
        for (String observation : OBSERVATIONS) {
            System.out.print(observation + ", ");
        }
        System.out.print("\n\nStart probability: ");
        for (int i = 0; i < STATES.length; i++) {
            System.out.print(STATES[i] + ": " + START_PROBABILITY[i] + ", ");
        }
        System.out.println("\n\nTransition probability:");
        for (int i = 0; i < STATES.length; i++) {
            System.out.print(" " + STATES[i] + ": {");
            for (int j = 0; j < STATES.length; j++) {
                System.out.print("  " + STATES[j] + ": " + TRANSITION_PROBABILITY[i][j] + ", ");
            }
            System.out.println("}");
        }
        System.out.println("\n\nEmission probability:");
        for (int i = 0; i < STATES.length; i++) {
            System.out.print(" " + STATES[i] + ": {");
            for (int j = 0; j < OBSERVATIONS.length; j++) {
                System.out.print("  " + OBSERVATIONS[j] + ": " + EMISSION_PROBABILITY[i][j] + ", ");
            }
            System.out.println("}");
        }
        forwardViterbi(OBSERVATIONS, STATES, START_PROBABILITY, TRANSITION_PROBABILITY, EMISSION_PROBABILITY);
    }
}
